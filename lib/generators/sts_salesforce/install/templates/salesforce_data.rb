class SalesforceData
    require 'rforce'
    require 'logger'
    require 'active_support/inflector'
    require 'salesforce_bulk'

    attr_accessor :org_email_addresses, :server_root

    def initialize(salesforce_org)
      begin
        raise "SalesforceOrg #{salesforce_org.name} is disabled due to #{salesforce_org.error_message}" if salesforce_org.disabled

        @username = salesforce_org.username
        @org_email_addresses = salesforce_org.email_addresses
        @pass = salesforce_org.password + salesforce_org.token
        @binding = RForce::Binding.new "https://#{salesforce_org.sandbox ? 'test' : 'login'}.salesforce.com/services/Soap/u/22.0"
        @sandbox = salesforce_org.sandbox
        @logger = ::Rails.logger
        Savon.configure do |config|
          config.log = true
          config.log_level = :debug
          config.logger = Rails.logger
        end
        HTTPI.log = false
        response = @binding.login @username, @pass

        raise "Password Expired" if response.to_hash[:loginResponse][:result][:passwordExpired] == 'true'

        @server_url = response.to_hash[:loginResponse][:result][:serverUrl]
        @server_root = @server_url[/(.*\.com\/)/,0]
        @session_id = response.to_hash[:loginResponse][:result][:sessionId]
        @logger.info response
      rescue => ex
        salesforce_org.update_attributes({ disabled: true, error_message: ex.message }) unless salesforce_org.disabled
        raise ex
      end
    end

    def bulk_api
      SalesforceBulk::Api.new(@username, @pass, @sandbox)
    end

    def query(query_clause)
      @logger.info "Executing query: #{query_clause}"
      response = @binding.query queryString: query_clause

      if response.queryResponse.nil? || response.queryResponse.result[:size].to_i == 0
        nil
      else
        records = response.queryResponse.result.records
        done = response.queryResponse.result.done
        queryLocator = response.queryResponse.result.queryLocator
        while done == 'false'
          @logger.info "Querying for more results..."
          response = @binding.queryMore queryLocator: queryLocator
          done = response.queryMoreResponse.result.done
          queryLocator = response.queryMoreResponse.result.queryLocator
          response.queryMoreResponse.result.records.each do |r|
            records << r
          end
        end
        @logger.info "Returning #{records.size} records"
        records
      end
    end

    def query_id(object, conditions)
        condition_clause = "where "
        conditions.each_key do |key|
            val = conditions[key]
            if val && val.kind_of?(String)
                val = val.gsub(/'/, "\\\\'")
            end

            value = "#{val}"

            condition_clause += "#{key}="
            condition_clause += "'" if !is_number?(val)
            condition_clause += value
            condition_clause += "'" if !is_number?(val)
            condition_clause += " and "
        end

        condition_clause = condition_clause.slice(0, condition_clause.size - 4)

        query = "select Id from #{object.to_s} #{condition_clause} limit 1"
        response = @binding.query queryString: query
        @logger.info response

        raise response[:Fault][:faultstring] if response[:Fault]

        if response.queryResponse.result[:size].to_i == 0
            nil
        else
            response.queryResponse.result.records.Id[0]
        end
    end

    def insert(object_name, properties, dedup_properties, dedup_properties2 = [], reinsert = false)
        conditions = Hash.new

        dedup_properties.each do |key|
            conditions.store(key, properties[key])
        end

        conditions2 = Hash.new

        dedup_properties2.each do |key|
            conditions2.store(key, properties[key])
        end

        object = Array.new
        object << :type << object_name

        properties.each do |key, value|
            object << key << value.to_s.strip
        end

        id = query_id(object_name, conditions)

        if id.nil? and !conditions2.empty?
            id = query_id(object_name, conditions2)
        end

        if id && reinsert
            @binding.delete(id: id)
            id = nil
        end

        if id.nil?
            @logger.info "Creating #{object_name} with properties #{properties.inspect}"
            response = @binding.create sObject: object
            @logger.info response
            if response[:Fault]
              raise response[:Fault][:faultstring]
            elsif response.createResponse.result.errors
              raise response.createResponse.result.errors.to_s
            else
              properties[:Id] = response.createResponse.result.id
            end
        else
            @logger.info "Existing #{object_name} found for #{properties.inspect}"
            properties[:Id] = id
        end

        properties
    end

    def reinsert(object_name, properties, dedup_properties, dedup_properties2 = [])
        insert(object_name, properties, dedup_properties, dedup_properties2, true)
    end

    def delete(id)
      @logger.info "Deleting Id: #{id}"
      response = @binding.delete Id: id
      @logger.info response
      response
    end

    def update(object_name, properties, match_properties, match_properties2 = [])
        conditions = Hash.new

        match_properties.each do |key|
            conditions.store(key, properties[key])
        end

        conditions2 = Hash.new

        match_properties2.each do |key|
            conditions2.store(key, properties[key])
        end

        object = Array.new
        object << :type << object_name

        properties.each do |key, value|
            object << key << value.to_s.strip
        end

        id = query_id(object_name, conditions)

        if id.nil? and !conditions2.empty?
            id = query_id(object_name, conditions2)
        end

        if id.nil?
            @logger.info "Unmatched #{object_name} with properties #{properties.inspect}"
        else
            @logger.info "Matched #{object_name} for #{properties.inspect}"
            properties[:Id] = id
            object << :Id << id unless object.include? :Id
            response = @binding.update sObject: object
            @logger.info response
            raise response[:Fault][:faultstring] if response[:Fault]
        end

        properties
    end

    def upsert(object_name, properties, key_field_name)

      object = Array.new
      object << :type << object_name
      object << :externalIdFieldName << key_field_name

      properties.each do |key, value|
        object << key << value.to_s.strip
      end

      response = @binding.upsert externalIdFieldName: key_field_name.to_s, sObject: object
      @logger.info response
      raise response[:Fault][:faultstring] if response[:Fault]
      properties[:Id] = response.upsertResponse.result.id

      properties
    end

    def call_webservice(endpoint_name, method_name, args = {})
      if endpoint_name.include? '__'
        package_name, service_name = endpoint_name.split('__')
      else
        package_name = nil
        service_name = endpoint_name
      end
      client = Savon::Client.new do |wsdl|
        wsdl.endpoint = 'https://' + URI.parse(@server_url).host + '/services/Soap/class/' + (package_name ? package_name + '/' : '') + service_name
        wsdl.namespace = "urn:soap.sforce.com"
      end

      response = client.request :ins0, method_name.to_sym do |soap|
        soap.header = {
            'SessionHeader' => {
                'sessionId' => @session_id
            }
        }
        soap.body = args
        soap.namespaces["xmlns:ins0"] = 'http://soap.sforce.com/schemas/class/' + (package_name ? package_name + '/' : '') + service_name
      end

      response.to_hash["#{method_name.to_s.underscore.to_sym}_response".to_sym]
    end

    def is_int?(str)
        true if Int(str) rescue false
    end

    def is_float?(str)
        true if Float(str) rescue false
    end

    def is_number?(val)
      val.kind_of?(Numeric) || val.kind_of?(Date)
    end

    class RowReader
        def initialize(column_map = nil, display_row_count = 0)
            @column_map = column_map
            @row_count = 0
            @display_row_count = display_row_count
        end

        def read(row)
            @current_row = row
            @row_count += 1
            puts 'Row ' + @row_count.to_s if @display_row_count > 0 && @row_count % @display_row_count == 0
        end

        def get(key, type = :string)
            if @column_map
                column_name = @column_map[key]
            else
                column_name = key
            end

            raise "Invalid column name: " + key.to_s if !column_name

            value = @current_row[column_name]

            if (!value || value == 'NULL')
                nil
            else
                case type
                    when :int
                        return value.delete(',').to_i
                    when :float
                        return value.delete(',').to_f
                    when :boolean
                        return value == 1 || value.upcase == 'Y' ||value.upcase == 'YES'
                    when :string
                        return value
                end
            end
        end
    end

end
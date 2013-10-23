
require 'logger'
require 'active_support/inflector'
require 'csv'
require 'yaml'
require 'set'

module StsSalesforce
  def address_name(row, account_name)
    address_name_2(row, account_name, row['SingletrackCMS__Line_1__c'], row['SingletrackCMS__City__c'], row['SingletrackCMS__Country_Picklist__c'])
  end

  def address_name_2(row, account_name, line_1, city, country)
    raise DataException.new("Useless Address", row) if (line_1 == '' && city == '' && country == '')
    business_street = line_1.gsub(/\n/, '')
    (account_name + ((business_street == '') ? '' : ', ' + business_street) + ((city == '') ? '' : ', ' + city))[0..79].strip
  end

  class RecordIdMatcher
    def initialize salesforce, object_name, matches, name = nil, mandatory = true
      @salesforce = salesforce
      @object_name = object_name
      @matches = (matches.is_a? Array) ? matches : [matches]
      @name = name
      @mandatory = mandatory
    end

    def call row
      record = nil

      @matches.each do |match|
        criteria = {}
        match.each do |key, value|
          value = value.call(row) if value.kind_of? Proc
          criteria[key] = value
        end

        record = @salesforce[@object_name].where(criteria)
        raise DataException.new("Multiple Matching #{@object_name}s", row) if record.is_a? Array
        return record.Id if !record.nil?
      end

      raise DataException.new("No Matching #{@object_name}#{@name.nil? ? '' : ' - ' + @name}", row) if @mandatory
    end
  end

  class SalesforceConnection
    def initialize(options)
      options.symbolize_keys!
      @client = Databasedotcom::Client.new(options)
      password = options[:password]
      password += options[:sec_token] if options[:sec_token]
      @client.authenticate(username: options[:username], password: password)
    end

    def materialize(object_name)
      @client.materialize(object_name)
    end

    def materialize_with_fields(object_name, query_fields)
      @client.materialize_with_fields(object_name, query_fields)
    end

    def query(soql)
      @client.query(soql)
    end

    def insert class_or_classname, attrs
      @client.create(class_or_classname,attrs)
    end

    def update class_or_classname, id , attrs
      @client.update(class_or_classname,attrs)
    end

    def upsert class_or_classname, field, value, attrs
      @client.upsert(class_or_classname,field,value,attrs)
    end

    def delete (class_or_classname, record_id)
      @client.delete(class_or_classname, record_id)
    end

    def call_webservice(endpoint_name, method_name, args = {})
      if endpoint_name.include? '__'
        package_name, service_name = endpoint_name.split('__')
      else
        package_name = nil
        service_name = endpoint_name
      end
      client = Savon::Client.new do |wsdl|
        wsdl.endpoint = 'https://' + URI.parse(@server_root).host + '/services/Soap/class/' + (package_name ? package_name + '/' : '') + service_name
        wsdl.namespace = "urn:soap.sforce.com"
      end

      response = client.request :ins0, method_name.to_sym do |soap|
        soap.header = {
            'SessionHeader' => {
                'sessionId' => @client.oauth_token
            }
        }
        soap.body = args
        soap.namespaces["xmlns:ins0"] = 'http://soap.sforce.com/schemas/class/' + (package_name ? package_name + '/' : '') + service_name
      end

      response.to_hash["#{method_name.to_s.underscore.to_sym}_response".to_sym]
    end

  end

  class SalesforceField
    # overrides new in the subclasses so we can use SalesforceField::new as a factory method
    class << self
      alias :__new__ :new

      def inherited(subclass)
        class << subclass
          alias :new :__new__
        end
      end
    end

    def initialize description
      @description = description
    end

    def convert value
      value
    end

    def value value_of
      value_of
    end

    def self.new description = {}
      case description['type']
        when 'textarea', 'string'
          SalesforceString.new(description)
        when 'boolean'
          SalesforceBoolean.new(description)
        when 'phone'
          SalesforcePhone.new(description)
        when 'id'
          SalesforceId.new(description)
        else
          SalesforceDefaultField.new(description)
      end
    end
  end

  class SalesforceDefaultField < SalesforceField
  end

  class SalesforceId < SalesforceField
    def value value_of
      value_of[0..14]
    end
  end

  class SalesforceString < SalesforceField
    def convert value
      return value if value.nil?
      value.slice(0, @description['length'])
    end
  end

  class SalesforceBoolean < SalesforceField
    def convert value
      return '' if value == ''
      return true if value == true
      return false if value == false

      case value.downcase
        when 'true', 'yes', 't', '1', 'y'
          true
        when 'false', 'no', 'f', '0', 'n'
          false
        else
          raise DataException.new("Invalid Boolean type: " + value)
      end
    end
  end

  class SalesforcePhone < SalesforceField
    def convert value
      return value if value.nil?
      value.gsub(/[^0-9\(\)\s+]/, '').strip.slice(0, @description['length'])
    end
  end

  # SalesforceObject represents both the Object and all the records in the system of that Object

  class SalesforceObject
    @@objects = {}

    def initialize(salesforce, object_name, scope = '', query_fields = [])
      @salesforce = salesforce
      @object_name = object_name
      @scope = scope
      @query_fields = query_fields
      @sobject = query_fields.empty? ? @salesforce.materialize(object_name) : @salesforce.materialize_with_fields(object_name, query_fields)
      @records = nil
      @cached_queries = {}
      @@objects[object_name] = self
    end

    def all
      @records = self.query_records if @records.nil?
      @records
    end

    def uniq property_name
      property_name = property_name.to_sym
      uniqs = Set.new
      self.all.each do |record|
        next if record[property_name].nil? || record[property_name] == ''
        uniqs << self.describe_field(property_name).value(record[property_name])
      end
      uniqs.to_a
    end

    def where(matches)
      query_key = matches.keys.join('|')

      if !@cached_queries.include? query_key
        @cached_queries[query_key] = {}

        self.all.each do |record|
          key = (matches.keys.collect { |key| self.describe_field(key).value(record[key]) }).join('|')
          next if key == ''

          @cached_queries[query_key][key] = [] if !@cached_queries[query_key].include? key
          @cached_queries[query_key][key] << record
        end
      end

      value_key = matches.values.join('|')
      matching_records = @cached_queries[query_key][value_key]

      if matching_records.nil?
        nil
      elsif matching_records.size == 1
        matching_records[0]
      else
        matching_records
      end
    end

    def describe_field(field_name)
      SalesforceField.new(@sobject.describe_field(field_name.to_s))
    end

    def self.[] object_name
      @@objects[object_name]
    end

    def query_records
      if (@scope && @scope != '')
        @sobject.query(@scope)
      else
        @sobject.all
      end
    end

    def backup
      self.all
      return nil if @records.empty?

      Dir.mkdir('backup') if !Dir.exist? 'backup'

      filename = "backup/backup-#{@object_name.downcase}-#{Time.now.strftime('%F-%H%M')}.csv"
      CSV.open(filename, "wb") do |out|
        fields = (@query_fields.empty? ? @records[0].attributes.keys : ['Id'].concat(@query_fields))
        out << fields

        @records.each do |record|
          out << fields.collect { |field| record[field] }
        end
      end

      filename
    end
  end

  # Salesforce acts as a wrapper for connections to Salesforce and a convenient shortcut for common functions

  class Salesforce

    attr_accessor :org_email_addresses, :server_root

    def initialize(config_file, config_name)
      @objects = {}
      @logger = Logger.new STDOUT
      @options = YAML.load_file(config_file)[config_name]
      @connection = SalesforceConnection.new(@options)
    end

    def initialize(salesforce_org)
      begin
        @username = salesforce_org.username
        @org_email_addresses = salesforce_org.email_addresses
        @pass = salesforce_org.password + salesforce_org.token
        @sandbox = salesforce_org.sandbox

        @objects = {}
        @logger = (defined?(Rails) && !Rails.logger.nil?) ? Rails.logger : Logger.new(STDOUT)

        Savon.configure do |config|
          config.log = true
          config.log_level = :debug
          config.logger = @logger
        end

        @options = {:host => "https://#{@sandbox ? 'test' : 'www'}.salesforce.com/services/Soap/u/22.0",
                    :username => @username,
                    :password => salesforce_org.password,
                    :sec_token => salesforce_org.token}

        @connection = SalesforceConnection.new(@options)

      #@server_root = @connection.client.instance_url
      rescue => ex
        salesforce_org.update_attributes({ disabled: true, error_message: ex.message }) unless salesforce_org.disabled
        raise ex
      end
    end

    def [] object_name
      raise ArgumentError.new("No object named #{object_name}") unless @objects.include? object_name
      @objects[object_name]
    end

    def backup query, *query_fields
      object = self.cache query, *query_fields
      object.backup
      object
    end

    def cache query, *query_fields
      query_parts = query.split(' where ')
      object_name = query_parts[0]
      scope = query_parts.size == 2 ? query_parts[1] : ''
      @objects[object_name] = SalesforceObject.new(self, object_name, scope, query_fields)
      @objects[object_name].all
      @objects[object_name]
    end

    def describe object_name
      @objects[object_name] = SalesforceObject.new(self, object_name) if !@objects.include? object_name
      @objects[object_name]
    end

    def is_sandbox?
      @sandbox
    end

    def materialize object_name
      @connection.materialize object_name
    end

    def materialize_with_fields object_name, query_fields
      @connection.materialize_with_fields object_name, query_fields
    end

    def query(soql)
      @connection.query(soql)
    end

    def bulk_api
      SalesforceBulk::Api.new(@username, @pass, @sandbox)
    end

    def insert class_or_classname, attrs
      @connection.create(class_or_classname,attrs)
    end

    def update class_or_classname, id , attrs
      @connection.update(class_or_classname,attrs)
    end

    def upsert class_or_classname, field, value, attrs
      @connection.upsert(class_or_classname,field,value,attrs)
    end

    def delete class_or_classname, record_id
      @connection.delete(class_or_classname,record_id)
    end

  end

  class DataException < StandardError
    attr_accessor :object

    def initialize(message = nil, object = nil)
      super(message)
      self.object = object
    end
  end

  class CSVProblemReporter
    def initialize(object_name = '')
      @object_name = object_name
      @problems = Array.new
    end

    def add_error(row, reason)
      add_row(row, 'Error', reason)
    end

    def add_warning(row, reason)
      add_row(row, 'Warning', reason)
    end

    def num_problems
      @problems.size
    end

    def num_errors
      @problems.select { |problem| problem['Type'] == 'Error' }.size
    end

    def num_warnings
      @problems.select { |problem| problem['Type'] == 'Warning' }.size
    end

    def add_row(row, type, reason)
      begin
        row['Type'] = type
        row['Reason'] = reason
      rescue TypeError => e
        row[row.size] = reason
      end
      @problems << row
    end

    def write_csv(to = STDOUT)
      begin
        to << @problems[0].headers.join(',') + "\n"
      rescue NoMethodError
      end

      @problems.each do |problem|
        begin
          to << problem.join(',') + "\n"
        rescue NoMethodError
          to << problem
        end
      end

      to.flush
    end
  end

  class ConvertibleCSVRow
    def initialize(row, index, object, column_names, settable_attributes, output_file)
      @row = row
      @index = index
      @object = object
      @column_names = column_names
      @settable_attributes = settable_attributes
      @output_file = output_file
      @converted = 0
      @additional_values = {}
    end

    def []=(key, value)
      @additional_values[key] = value
    end

    def [](key)
      (@additional_values.include? key) ? @additional_values[key] : @row[key]
    end

    def index
      @index
    end

    def converted?
      @converted > 0
    end

    def converted
      @converted
    end

    def convert
      fields = []

      @column_names.each do |column|
        description = @object.describe_field(column)
        fields << description.convert(self[column])
      end

      @output_file << fields
      @converted += 1
      @settable_attributes.each { |column_name| self[column_name] = nil }
    end
  end

end


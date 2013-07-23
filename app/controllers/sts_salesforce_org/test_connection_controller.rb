module StsSalesforceOrg
  class TestConnectionController < ApplicationController

    def test_conn

      begin
        salesforce_org = SalesforceOrg.new()
        salesforce_org.username = params['salesforce_org']['username']
        salesforce_org.password = params['salesforce_org']['password']
        salesforce_org.token = params['salesforce_org']['token']
        response = SalesforceData.new(salesforce_org)
        render :json => '{"message" : "Connection Successful"}'
      rescue Exception => e
        render :json => '{"message" : "Connection Failed"}'
      end

    end

  end
end
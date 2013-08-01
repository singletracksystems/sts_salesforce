require 'spec_helper'

describe SalesforceData do

  it "should call a webservice method" do

    sf = SalesforceOrg.new(name: 'Build-2', packaged: false, sandbox: false, username: 'test-build-2@singletracksystems.com', password: 't35tu53r', token: '')
    sf.save

    sf_data = SalesforceData.new(sf)

    result = sf_data.call_webservice 'PortalWebService', 'getCacheInfo'

    result[:site_meta_timestamp].should_not == ''

  end

  it "should call a packaged webservice method" do

    sf = SalesforceOrg.new(name: 'QA', packaged: true, sandbox: false, username: 'mailer-api-qa@singletracksystems.com', password: 't35tu53r', token: 'IoDf3yYlkZZNWxY3cBgnil8p')
    sf.save

    sf_data = SalesforceData.new(sf)

    result = sf_data.call_webservice 'SingletrackCMS__PortalWebService', 'getCacheInfo'

    result[:site_meta_timestamp].should_not == ''

  end

  it "should raise an error if the SalesforceOrg is disabled" do

    sf = SalesforceOrg.create(name: 'Build-2', packaged: false, sandbox: false, username: 'test-build-2@singletracksystems.com', password: 't35tu53r', token: '', disabled: '1', error_message: 'Invalid username/password')

    RForce::Binding.should_not_receive(:new)

    lambda { SalesforceData.new(sf) }.should raise_error 'SalesforceOrg Build-2 is disabled due to Invalid username/password'

  end


  it "should disable the SalesforceOrg if authentication to Salesforce fails" do

    sf = SalesforceOrg.create(name: 'Build-2', packaged: false, sandbox: false, username: 'zzzzzzzzz@singletracksystems.com', password: 'zzzzz', token: '')

    lambda { SalesforceData.new(sf) }.should raise_error 'Incorrect user name / password []'

    sf.reload

    sf.disabled.should be_true
    sf.error_message.should == 'Incorrect user name / password []'

  end

end
require 'spec_helper'
require File.expand_path('../../../app/models/salesforce_org', __FILE__)

describe SalesforceOrg do

  it "should clear the error_message is the disabled flag is cleared via save" do
    sa = SalesforceOrg.create(disabled: '1', error_message: 'Invalid username/password')

    sa.disabled = '0'
    sa.save

    sa.reload

    sa.error_message.should be_nil
  end

  it "should clear the error_message is the disabled flag is cleared via update_attribute" do
    sa = SalesforceOrg.create(disabled: '1', error_message: 'Invalid username/password')

    sa.update_attribute(:disabled, '0')

    sa.reload

    sa.error_message.should be_nil
  end

  it "should clear the error_message is the disabled flag is cleared via update_attributes" do
    sa = SalesforceOrg.create(disabled: '1', error_message: 'Invalid username/password')

    sa.update_attributes(disabled: '0')

    sa.reload

    sa.error_message.should be_nil
  end

end

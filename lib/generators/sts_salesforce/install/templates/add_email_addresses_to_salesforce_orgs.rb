class AddEmailAddressesToSalesforceOrgs < ActiveRecord::Migration
  def change
    add_column :salesforce_orgs, :email_addresses, :string
  end
end

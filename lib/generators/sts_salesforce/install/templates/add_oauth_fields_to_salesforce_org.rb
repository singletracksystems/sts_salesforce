class AddOauthFieldsToSalesforceOrg < ActiveRecord::Migration
  def change
    add_column :salesforce_orgs, :client_id, :string
    add_column :salesforce_orgs, :client_secret_encrypted, :string
  end
end

class AddErrorMessageToSalesforceOrg < ActiveRecord::Migration
  def change
    add_column :salesforce_orgs, :error_message, :string
  end
end

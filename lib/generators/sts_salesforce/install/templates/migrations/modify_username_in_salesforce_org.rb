class ModifyUsernameInSalesforceOrg < ActiveRecord::Migration
  def change
    if SalesforceOrg.column_names.include?('username')
      remove_column :salesforce_orgs, :username, :string
      remove_column :salesforce_orgs, :username_encrypted, :string
    end
  end
end

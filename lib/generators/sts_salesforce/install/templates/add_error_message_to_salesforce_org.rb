class AddErrorMessageToSalesforceOrg < ActiveRecord::Migration
  def change
    if !SalesforceOrg.column_names.include?('error_message')
      add_column :salesforce_orgs, :error_message, :string
    end
  end
end

class AddDisabledToSalesforceOrg < ActiveRecord::Migration
  def change
    add_column :salesforce_orgs, :disabled, :boolean
  end
end

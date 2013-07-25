class AddOrganizationIdToSalesforceOrg < ActiveRecord::Migration
  def self.up
    add_column :salesforce_orgs, :organization_id, :string
  end

  def self.down
    remove_column :salesforce_orgs, :organization_id
  end
end

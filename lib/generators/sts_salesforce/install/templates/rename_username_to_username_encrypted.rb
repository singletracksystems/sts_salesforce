class RenameUsernameToUsernameEncrypted < ActiveRecord::Migration
  def change
    if SalesforceOrg.column_names.include?('username')
      rename_column :salesforce_orgs, :username, :username_encrypted
    end
  end
end

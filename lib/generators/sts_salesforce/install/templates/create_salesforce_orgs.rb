class CreateSalesforceOrgs < ActiveRecord::Migration
def change
    create_table :salesforce_orgs do |t|
      t.string :name
      t.boolean :packaged
      t.boolean :sandbox
      t.string :username
      t.string :password_encrypted
      t.string :token_encrypted

      t.timestamps
    end
  end
end

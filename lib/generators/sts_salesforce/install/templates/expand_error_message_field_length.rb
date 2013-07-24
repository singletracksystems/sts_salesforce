class ExpandErrorMessageFieldLength < ActiveRecord::Migration
  def change
    change_column :salesforce_orgs, :error_message, :string, limit: 102400
  end
end

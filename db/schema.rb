ActiveRecord::Schema.define(:version => 20130801090900) do

  create_table "salesforce_orgs", :force => true do |t|
    t.string   "name"
    t.boolean  "packaged"
    t.boolean  "sandbox"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "username_encrypted"
    t.string   "password_encrypted"
    t.string   "token_encrypted"
    t.string   "organization_id"
    t.boolean  "disabled"
    t.string   "error_message",      :limit => 102400
    t.string   "email_addresses"
  end

end

ActiveAdmin.register SalesforceOrg do
  filter :name

  form :partial => "form"

  index do
    column :name
    column :username
    column :packaged
    column :sandbox
    column :disabled

    default_actions
  end

  show title: :name do |s|
    attributes_table :name, :username, :packaged, :sandbox, :disabled, :error_message, :created_at, :updated_at

    render "test_connection" , :salesforce_org => s
  end

end

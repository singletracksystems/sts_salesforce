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

=begin
  form do |f|
    f.inputs "Details" do
      f.input :name
      f.input :username
      f.input :password, as: :password, input_html: { value: f.object.password }
      f.input :token, as: :password, input_html: { value: f.object.password }
      f.input :packaged
      f.input :sandbox
      f.input :disabled
    end
    f.buttons
  end
=end

end

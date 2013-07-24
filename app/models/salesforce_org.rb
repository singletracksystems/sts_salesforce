class SalesforceOrg < ActiveRecord::Base
  attr_accessible :name, :packaged, :password, :sandbox, :token, :username, :disabled, :error_message

  attr_encrypted :username, :attribute => 'username_encrypted', :key => Rails.application.config.db_encryption_key
  attr_encrypted :password, :attribute => 'password_encrypted', :key => Rails.application.config.db_encryption_key
  attr_encrypted :token,    :attribute => 'token_encrypted',    :key => Rails.application.config.db_encryption_key

  def disabled=(disabled)
    write_attribute(:error_message, nil) if disabled == '0'
    write_attribute(:disabled, disabled)
  end
end

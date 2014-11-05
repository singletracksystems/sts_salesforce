class SalesforceOrg < ActiveRecord::Base

  default_scope order('name asc')
   
  attr_accessible :name, :packaged, :password, :sandbox, :token, :username, :disabled, :error_message, :organization_id, :email_addresses

  attr_encrypted :username, :attribute => 'username_encrypted', :key => (Rails.application ? Rails.application.config.db_encryption_key : 'r0-wfojomLCbsLqYxDBsHjnEDEMWTo')
  attr_encrypted :password, :attribute => 'password_encrypted', :key => (Rails.application ? Rails.application.config.db_encryption_key : 'r0-wfojomLCbsLqYxDBsHjnEDEMWTo')
  attr_encrypted :token,    :attribute => 'token_encrypted',    :key => (Rails.application ? Rails.application.config.db_encryption_key : 'r0-wfojomLCbsLqYxDBsHjnEDEMWTo')

  def disabled=(disabled)
    write_attribute(:error_message, nil) if disabled == '0'
    write_attribute(:disabled, disabled)
  end
end

module StsSalesforceOrg
  class SalesforceOrg < ActiveRecord::Base
    attr_accessible :name, :packaged, :password, :sandbox, :token, :username, :disabled, :error_message
    attr_encrypted :password, :attribute => 'password_encrypted', :key => Rails.Application.config.db_encryption_key
    attr_encrypted :token,    :attribute => 'token_encrypted',    :key => Rails.Application.config.db_encryption_key
    #has_many :monitored_activities

    def disabled=(disabled)
      write_attribute(:error_message, nil) if disabled == '0'
      write_attribute(:disabled, disabled)
    end
  end
end

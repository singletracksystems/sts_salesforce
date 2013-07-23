require 'rails/generators/active_record'

module StsSalesforceOrg
  module Generators
    class InstallGenerator < ActiveRecord::Generators::Base

      source_root File.expand_path('../templates', __FILE__ )

      desc "add migrations"

      def copy_migrations
        copy_migration "create_salesforce_org"
        copy_migration "add_disabled_to_salesforce_org"
        copy_migration "add_error_message_to_salesforce_org"
        copy_migration "expand_error_message_field_length"
      end

    protected

      def copy_migration(filename)
        if self.class.migration_exists?("db/migrate", "#{filename}")
          say_status("skipped", "Migration #{filename}.rb already exists")
        else
          migration_template "migrations/#{filename}.rb", "db/migrate/#{filename}.rb"
        end
      end

    end
  end
end

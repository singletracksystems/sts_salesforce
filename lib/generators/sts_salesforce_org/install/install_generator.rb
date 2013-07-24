require 'rails/generators/migration'
require 'rails/generators/active_record/migration'

module StsSalesforceOrg
  module Generators
    class InstallGenerator < ::Rails::Generators::Base
      include Rails::Generators::Migration
      extend ActiveRecord::Generators::Migration

      source_root File.expand_path('../templates', __FILE__ )

      desc "add migrations"

      def self.next_migration_number(path)
        unless @prev_migration_nr
          @prev_migration_nr = Time.now.utc.strftime("%Y%m%d%H%M%S").to_i
        else
          @prev_migration_nr += 1
        end
        @prev_migration_nr.to_s
      end

      def copy_migrations
        copy_migration "create_salesforce_orgs"
        copy_migration "add_disabled_to_salesforce_org"
        copy_migration "add_error_message_to_salesforce_org"
        copy_migration "expand_error_message_field_length"
      end

      def install_assets
        template 'sts_salesforce_org.js', 'app/assets/javascripts/sts_salesforce_org.js'
        template 'sts_salesforce_org.css', 'app/assets/stylesheets/sts_salesforce_org.css'
      end

      def install_resources
        template "salesforce_orgs.rb", "app/admin/salesforce_orgs.rb"
      end

      protected

      def copy_migration(filename)
        if self.class.migration_exists?("db/migrate", "#{filename}")
          say_status("skipped", "Migration #{filename}.rb already exists")
        else
          migration_template "/migrations/#{filename}.rb", "db/migrate/#{filename}.rb"
        end
      end

    end
  end
end

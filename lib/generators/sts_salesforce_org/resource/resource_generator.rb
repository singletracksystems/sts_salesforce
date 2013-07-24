module StsSalesforceOrg
  module Generators
    class ResourceGenerator < Rails::Generators::NamedBase

      source_root File.expand_path("../templates", __FILE__)

      def generate_config_file
        template "salesforce_orgs.rb", "app/admin/salesforce_orgs.rb"
      end

    end
  end
end

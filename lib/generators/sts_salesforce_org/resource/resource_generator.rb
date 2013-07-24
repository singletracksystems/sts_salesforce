module StsSalesforceOrg
  module Generators
    class ResourceGenerator < Rails::Generators::Base

      source_root File.expand_path("../templates", __FILE__)

      def generate_activeadmin_tab
        template "salesforce_orgs.rb", "app/admin/salesforce_orgs.rb"
      end

    end
  end
end

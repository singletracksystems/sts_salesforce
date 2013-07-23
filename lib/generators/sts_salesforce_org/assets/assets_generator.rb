module StsSalesforceOrg
  module Generators
    class AssetsGenerator < Rails::Generators::Base

      source_root File.expand_path('../templates', __File__ )

      desc "add assets"

      def install_assets
        template 'sts_salesforce_org.js', 'app/assets/javascripts/sts_salesforce_org.js'
        template 'sts_salesforce_org.css', 'app/assets/stylesheets/sts_salesforce_org.css'
      end

    end
  end
end
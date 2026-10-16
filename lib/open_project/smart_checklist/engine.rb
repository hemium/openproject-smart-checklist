# frozen_string_literal: true

# Prevent load-order problems in case openproject-plugins is listed after a plugin in the Gemfile
# or not at all
require "open_project/plugins"

require_relative "patches/api/work_package_representer"
require_relative "patches/api/work_package_schema_representer"

module OpenProject
  module SmartChecklist
    # Rails engine registering the Smart Checklist plugin.
    class Engine < ::Rails::Engine
      engine_name :openproject_smart_checklist

      include OpenProject::Plugins::ActsAsOpEngine

      register "openproject-smart_checklist",
               author_url: "https://github.com/hemium",
               requires_openproject: ">= 17.3.0"

      patches %i[WorkPackage]
      patch_with_namespace :WorkPackages, :BaseContract

      extend_api_response(:v3, :work_packages, :work_package,
                          &::OpenProject::SmartChecklist::Patches::API::WorkPackageRepresenter.extension)

      extend_api_response(:v3, :work_packages, :work_package_payload,
                          &::OpenProject::SmartChecklist::Patches::API::WorkPackageRepresenter.extension)

      extend_api_response(:v3, :work_packages, :schema, :work_package_schema,
                          &::OpenProject::SmartChecklist::Patches::API::WorkPackageSchemaRepresenter.extension)
    end
  end
end

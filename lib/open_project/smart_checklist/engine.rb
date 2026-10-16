# frozen_string_literal: true

# Prevent load-order problems in case openproject-plugins is listed after a plugin in the Gemfile
# or not at all
require "open_project/plugins"

module OpenProject
  module SmartChecklist
    # Rails engine registering the Smart Checklist plugin.
    class Engine < ::Rails::Engine
      engine_name :openproject_smart_checklist

      include OpenProject::Plugins::ActsAsOpEngine

      register "openproject-smart_checklist",
               author_url: "https://github.com/hemium",
               requires_openproject: ">= 17.3.0"
    end
  end
end

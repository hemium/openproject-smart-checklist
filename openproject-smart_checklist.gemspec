# frozen_string_literal: true

$LOAD_PATH.push File.expand_path("lib", __dir__)

require "open_project/smart_checklist/version"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = "openproject-smart_checklist"
  s.version     = OpenProject::SmartChecklist::VERSION

  s.authors     = "hemium"
  s.email       = "hemium99@gmail.com"
  s.homepage    = "https://github.com/hemium/openproject-smart-checklist"
  s.summary     = "Jira-style smart checklists for OpenProject work packages"
  s.description = "Adds Jira-style smart checklists to OpenProject work packages, " \
                  "letting teams track lightweight to-do items inside a work package."

  s.required_ruby_version = ">= 3.4"
  s.license = "GPL-3.0"

  s.files = Dir["{app,config,db,lib}/**/*"] + %w[CHANGELOG.md README.md]
  s.metadata["rubygems_mfa_required"] = "true"
end

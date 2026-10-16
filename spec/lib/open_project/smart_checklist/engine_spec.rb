# frozen_string_literal: true

require 'spec_helper'

RSpec.describe OpenProject::SmartChecklist::Engine do
  it 'registers the plugin' do
    expect(Redmine::Plugin.find(:openproject_smart_checklist)).not_to be_nil
  end
end

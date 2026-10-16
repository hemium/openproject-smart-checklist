# frozen_string_literal: true

require "spec_helper"

RSpec.describe Type, "work package form attributes" do
  it "does not expose smart_checklist in the form" do
    expect(described_class.translated_work_package_form_attributes).not_to include("smart_checklist")
    expect(described_class.translated_work_package_form_attributes).to include("priority")
  end
end

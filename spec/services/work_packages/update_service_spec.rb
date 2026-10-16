# frozen_string_literal: true

require "spec_helper"

RSpec.describe WorkPackages::UpdateService, "smart checklist journaling" do
  let(:user) { create(:admin) }
  let(:work_package) { create(:work_package, smart_checklist: "- [ ] old") }

  it "creates a journal entry when only the checklist changes" do
    result = nil

    expect do
      result = described_class
        .new(user:, model: work_package)
        .call(smart_checklist: "- [x] new")
    end.to change { work_package.journals.count }.by(1)

    expect(result).to be_success
    journal = work_package.journals.reorder(:id).last
    expect(journal.data.smart_checklist).to eq "- [x] new"
    expect(journal.details["smart_checklist"]).to eq ["- [ ] old", "- [x] new"]
  end
end

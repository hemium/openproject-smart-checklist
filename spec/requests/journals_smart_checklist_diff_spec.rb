# frozen_string_literal: true

require "spec_helper"

RSpec.describe "Journal diff for smart_checklist", # rubocop:disable RSpec/DescribeClass
               type: :rails_request do
  let(:project) { create(:project) }
  let(:role) { create(:project_role, permissions: %i[view_work_packages]) }
  let(:viewer) { create(:user, member_with_roles: { project => role }) }
  let(:editor) { create(:admin) }
  let(:work_package) { create(:work_package, project:, smart_checklist: "- [ ] old item") }
  let!(:journal) do
    WorkPackages::UpdateService
      .new(user: editor, model: work_package)
      .call(smart_checklist: "- [x] new item")
    work_package.journals.reorder(:id).last
  end

  current_user { viewer }

  it "renders the old and new checklist text" do
    get diff_journal_path(journal, field: "smart_checklist")

    expect(response).to have_http_status(:ok)
    expect(response.body).to include("text-diff")
    # The word-level diff splits tokens across <ins>/<del> tags
    expect(response.body).to include("[x] new")
    expect(response.body).to include("] old")
  end

  it "still 404s for unknown fields" do
    get diff_journal_path(journal, field: "foo")

    expect(response).to have_http_status(:not_found)
  end
end

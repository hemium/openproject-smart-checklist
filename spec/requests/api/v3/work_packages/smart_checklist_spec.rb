# frozen_string_literal: true

require "spec_helper"
require "rack/test"

RSpec.describe "API v3 work package smart checklist", # rubocop:disable RSpec/DescribeClass
               content_type: :json do
  include API::V3::Utilities::PathHelper

  shared_let(:project) { create(:project, public: false) }
  shared_let(:type) { project.types.first }
  shared_let(:status) { create(:status, is_default: true) }
  shared_let(:priority) { create(:priority, is_default: true) }
  shared_let(:work_package) do
    create(:work_package,
           project:,
           type:,
           status:,
           priority:,
           smart_checklist: "- [ ] a\n- [x] b")
  end

  let(:role) { create(:project_role, permissions:) }
  let(:permissions) { %i[view_work_packages edit_work_packages] }

  current_user do
    create(:user, member_with_roles: { project => role })
  end

  describe "GET /api/v3/work_packages/:id" do
    let(:path) { api_v3_paths.work_package(work_package.id) }

    before do
      get path
    end

    it "responds with 200" do
      expect(last_response).to have_http_status 200
    end

    it "includes smartChecklist" do
      expect(last_response.body)
        .to be_json_eql("- [ ] a\n- [x] b".to_json)
        .at_path("smartChecklist")
    end

    it "includes smartChecklistProgress" do
      expect(last_response.body)
        .to be_json_eql(
          { total: 2, done: 1, inProgress: 0, skipped: 0, todo: 1, percent: 50 }.to_json
        )
        .at_path("smartChecklistProgress")
    end
  end

  describe "PATCH /api/v3/work_packages/:id" do
    let(:path) { api_v3_paths.work_package(work_package.id) }
    let(:parameters) do
      {
        smartChecklist: "- [ ] new\n- [-] skipped",
        lockVersion: work_package.lock_version
      }
    end

    before do
      patch path, parameters.to_json
    end

    context "with edit_work_packages permission" do
      it "responds with 200" do
        expect(last_response).to have_http_status 200
      end

      it "persists the checklist" do
        expect(work_package.reload.smart_checklist).to eq "- [ ] new\n- [-] skipped"
      end
    end

    context "with only view_work_packages permission" do
      let(:permissions) { %i[view_work_packages] }

      it "is rejected" do
        expect(last_response).to have_http_status 403
      end
    end
  end

  describe "GET /api/v3/work_packages/schemas/:project-:type" do
    let(:path) { api_v3_paths.work_package_schema(project.id, type.id) }

    before do
      get path
    end

    it "contains a writable smartChecklist attribute" do
      expect(last_response).to have_http_status 200
      expect(last_response.body)
        .to be_json_eql(true.to_json)
        .at_path("smartChecklist/writable")
    end
  end
end

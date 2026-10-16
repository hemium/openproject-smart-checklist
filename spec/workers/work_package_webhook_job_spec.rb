# frozen_string_literal: true

require "spec_helper"

RSpec.describe WorkPackageWebhookJob, "smart checklist", :webmock, type: :model do
  include_context "with ssrf webhook stubs"

  shared_let(:user) { create(:admin) }
  shared_let(:request_url) { "http://example.net/test/42" }
  shared_let(:checklist_text) { "- [ ] a\n- [x] b" }
  shared_let(:work_package) { create(:work_package, smart_checklist: checklist_text) }
  shared_let(:webhook) { create(:webhook, all_projects: true, url: request_url, secret: nil) }

  describe "payload contents" do
    let(:event) { "work_package:updated" }
    let(:job) { described_class.perform_now webhook.id, work_package, event, actor: nil }

    let!(:stub) do
      stub_request(:post, request_url)
        .with(
          body: hash_including(
            "action" => event,
            "work_package" => hash_including(
              "_type" => "WorkPackage",
              "smartChecklist" => checklist_text,
              "smartChecklistProgress" => hash_including(
                "total" => 2,
                "done" => 1,
                "percent" => 50
              )
            )
          )
        )
        .to_return(status: 200, body: "hook called", headers: { content_type: "text/plain" })
    end

    before do
      allow(Webhooks::Webhook).to receive(:find).with(webhook.id).and_return(webhook)
      stub
    end

    it "posts smartChecklist and smartChecklistProgress" do
      job
      expect(stub).to have_been_requested
    end
  end

  describe "triggering via the journal-ready event" do
    let(:event_name) { "work_package:updated" }
    let!(:webhook) { create(:webhook, all_projects: true, url: request_url, event_names: [event_name]) }

    it "enqueues the webhook job when the checklist changes" do
      # A non-initial journal maps to "work_package:updated"
      WorkPackages::UpdateService
        .new(user:, model: work_package)
        .call(smart_checklist: "- [x] updated")
      journal = work_package.journals.reorder(:id).last

      expect do
        OpenProject::Notifications.send(
          OpenProject::Events::AGGREGATED_WORK_PACKAGE_JOURNAL_READY,
          journal:,
          send_mail: false
        )
      end.to have_enqueued_job(described_class)
    end
  end
end

# frozen_string_literal: true

module OpenProject::SmartChecklist::Patches::BaseContractPatch
  extend ActiveSupport::Concern

  included do
    # Deliberate v1 simplification: any user allowed to update the work package
    # (edit_work_packages etc., enforced by UpdateContract) may edit the checklist.
    attribute :smart_checklist
  end
end

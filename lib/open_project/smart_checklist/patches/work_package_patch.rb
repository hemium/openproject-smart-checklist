# frozen_string_literal: true

module OpenProject::SmartChecklist::Patches::WorkPackagePatch
  extend ActiveSupport::Concern

  included do
    register_journal_formatted_fields "smart_checklist", formatter_key: :diff
  end
end

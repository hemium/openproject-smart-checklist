# frozen_string_literal: true

# JournalsController#ensure_valid_for_diffing whitelists which journal fields may
# be diffed. Allow smart_checklist in addition to the core whitelist.
module OpenProject::SmartChecklist::Patches::JournalsControllerPatch
  private

  def ensure_valid_for_diffing
    return if field_param == "smart_checklist"

    super
  end
end

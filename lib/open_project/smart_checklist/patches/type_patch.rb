# frozen_string_literal: true

# Hides the raw smart_checklist attribute from the work package form's
# attribute groups. The attribute stays writable through the API schema
# (the Checklist tab relies on isAttributeEditable).
module OpenProject::SmartChecklist::Patches::TypePatch
  private

  def skipped_attribute?(key, definition)
    return true if key == "smart_checklist"

    super
  end
end

# frozen_string_literal: true

module OpenProject::SmartChecklist::Patches
  module API
    module WorkPackageSchemaRepresenter
      module_function

      def extension
        ->(*) do
          schema :smart_checklist,
                 type: "String",
                 required: false
        end
      end
    end
  end
end

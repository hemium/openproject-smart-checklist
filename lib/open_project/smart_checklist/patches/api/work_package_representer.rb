# frozen_string_literal: true

module OpenProject::SmartChecklist::Patches
  module API
    module WorkPackageRepresenter
      module_function

      def extension
        ->(*) do
          property :smart_checklist,
                   render_nil: true

          property :smart_checklist_progress,
                   render_nil: true,
                   exec_context: :decorator,
                   getter: ->(*) do
                     progress = ::OpenProject::SmartChecklist::Parser.progress(represented.smart_checklist)

                     {
                       total: progress[:total],
                       done: progress[:done],
                       inProgress: progress[:inProgress],
                       skipped: progress[:skipped],
                       todo: progress[:todo],
                       percent: progress[:percent]
                     }
                   end
        end
      end
    end
  end
end

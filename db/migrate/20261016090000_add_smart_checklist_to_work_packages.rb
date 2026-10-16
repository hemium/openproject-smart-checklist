# frozen_string_literal: true

class AddSmartChecklistToWorkPackages < ActiveRecord::Migration[7.1]
  def change
    add_column :work_packages, :smart_checklist, :text
    add_column :work_package_journals, :smart_checklist, :text
  end
end

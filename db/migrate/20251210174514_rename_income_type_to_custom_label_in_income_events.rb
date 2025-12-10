class RenameIncomeTypeToCustomLabelInIncomeEvents < ActiveRecord::Migration[7.1]
  def change
    rename_column :income_events, :income_type, :custom_label
    change_column_null :income_events, :custom_label, true
    change_column_default :income_events, :custom_label, nil
  end
end

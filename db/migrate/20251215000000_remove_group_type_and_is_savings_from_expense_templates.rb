class RemoveGroupTypeAndIsSavingsFromExpenseTemplates < ActiveRecord::Migration[7.1]
  def change
    # Remove the index that includes group_type first
    if index_exists?(:expense_templates, [:user_id, :group_type], name: "index_expense_templates_on_user_id_and_group_type")
      remove_index :expense_templates, name: "index_expense_templates_on_user_id_and_group_type"
    end
    
    # Remove the columns
    remove_column :expense_templates, :group_type, :integer if column_exists?(:expense_templates, :group_type)
    remove_column :expense_templates, :is_savings, :boolean if column_exists?(:expense_templates, :is_savings)
  end
end


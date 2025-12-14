class CleanUpExpensesTable < ActiveRecord::Migration[7.1]
  def change
    remove_column :expenses, :group_type, :integer if column_exists?(:expenses, :group_type)
    remove_column :expenses, :is_savings, :boolean if column_exists?(:expenses, :is_savings)
  end
end

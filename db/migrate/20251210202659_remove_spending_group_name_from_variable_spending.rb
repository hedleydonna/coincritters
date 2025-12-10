class RemoveSpendingGroupNameFromVariableSpending < ActiveRecord::Migration[7.1]
  def change
    # Remove index that includes spending_group_name first
    remove_index :variable_spending, [:envelope_id, :spending_group_name] if index_exists?(:variable_spending, [:envelope_id, :spending_group_name])
    # Then remove the column
    remove_column :variable_spending, :spending_group_name, :string if column_exists?(:variable_spending, :spending_group_name)
  end
end

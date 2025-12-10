class AddSpendingCategoryToEnvelopesAndRemoveGroupType < ActiveRecord::Migration[7.1]
  def change
    # Add spending_category_id foreign key
    add_reference :envelopes, :spending_category, null: false, foreign_key: { on_delete: :cascade }
    
    # Remove old columns that are now in spending_categories
    remove_column :envelopes, :group_type, :integer if column_exists?(:envelopes, :group_type)
    remove_column :envelopes, :is_savings, :boolean if column_exists?(:envelopes, :is_savings)
    
    # Update the unique index: one envelope per spending_category per monthly_budget
    remove_index :envelopes, [:monthly_budget_id, :spending_group_name] if index_exists?(:envelopes, [:monthly_budget_id, :spending_group_name])
    add_index :envelopes, [:monthly_budget_id, :spending_category_id], 
              unique: true, 
              name: "index_envelopes_on_budget_and_spending_category"
  end
end

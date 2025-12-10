class RemoveSpentAmountAndSpendingGroupNameFromEnvelopes < ActiveRecord::Migration[7.1]
  def change
    # Remove spent_amount - now calculated from spendings table
    remove_column :envelopes, :spent_amount, :decimal, precision: 12, scale: 2
    
    # Remove spending_group_name - now comes from spending_category.name
    remove_column :envelopes, :spending_group_name, :string
    
    # Remove the old index that was on monthly_budget_id + spending_group_name
    # The new unique index is on monthly_budget_id + spending_category_id
    remove_index :envelopes, name: "index_envelopes_on_budget_and_name", if_exists: true
  end
end

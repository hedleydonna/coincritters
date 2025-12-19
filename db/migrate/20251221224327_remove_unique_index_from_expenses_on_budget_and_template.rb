class RemoveUniqueIndexFromExpensesOnBudgetAndTemplate < ActiveRecord::Migration[7.1]
  def change
    # Remove the unique index that prevents multiple expenses per template per budget
    # This is needed to support weekly/bi-weekly expenses where we need multiple
    # expense entries for the same template in the same month
    remove_index :expenses, 
                 name: "index_expenses_on_budget_and_template_when_template_present",
                 if_exists: true
    
    # Add a non-unique index for the same columns for query performance
    add_index :expenses, 
              [:monthly_budget_id, :expense_template_id],
              name: "index_expenses_on_budget_and_template",
              where: "(expense_template_id IS NOT NULL)"
  end
end

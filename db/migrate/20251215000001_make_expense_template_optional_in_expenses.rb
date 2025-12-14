class MakeExpenseTemplateOptionalInExpenses < ActiveRecord::Migration[7.1]
  def change
    # Make expense_template_id nullable to allow one-off expenses
    change_column_null :expenses, :expense_template_id, true
    
    # Foreign key constraint can remain - PostgreSQL foreign keys work fine with nulls
    # We don't need to remove/re-add it
    
    # Update the uniqueness index to handle nulls properly
    # PostgreSQL treats nulls as distinct, but we need a partial unique index
    # Remove the old unique index if it exists
    if index_exists?(:expenses, [:monthly_budget_id, :expense_template_id], name: "index_envelopes_on_budget_and_envelope_template")
      remove_index :expenses, name: "index_envelopes_on_budget_and_envelope_template"
    end
    
    # Add partial unique index that only applies when expense_template_id is not null
    # This ensures one expense per template per budget (when template exists)
    # When template is null, we rely on name uniqueness instead
    add_index :expenses, [:monthly_budget_id, :expense_template_id], 
              unique: true, 
              name: "index_expenses_on_budget_and_template_when_template_present",
              where: "expense_template_id IS NOT NULL"
    
    # The name uniqueness is already handled by index_envelopes_on_budget_and_name_override
    # Name validation is handled in the model (required when expense_template_id is null)
  end
end


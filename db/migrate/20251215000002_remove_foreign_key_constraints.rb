class RemoveForeignKeyConstraints < ActiveRecord::Migration[7.1]
  def change
    # Remove all foreign key constraints
    # Keep the indexes - they're still valuable for query performance
    # Referential integrity is handled at the model level via belongs_to validations
    
    remove_foreign_key :expense_templates, :users if foreign_key_exists?(:expense_templates, :users)
    remove_foreign_key :expenses, :expense_templates if foreign_key_exists?(:expenses, :expense_templates)
    remove_foreign_key :expenses, :monthly_budgets if foreign_key_exists?(:expenses, :monthly_budgets)
    remove_foreign_key :income_events, :incomes if foreign_key_exists?(:income_events, :incomes)
    remove_foreign_key :income_events, :users if foreign_key_exists?(:income_events, :users)
    remove_foreign_key :incomes, :users if foreign_key_exists?(:incomes, :users)
    remove_foreign_key :monthly_budgets, :users if foreign_key_exists?(:monthly_budgets, :users)
    remove_foreign_key :payments, :expenses if foreign_key_exists?(:payments, :expenses)
  end
end


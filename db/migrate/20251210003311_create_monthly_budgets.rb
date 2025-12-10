# db/migrate/20251210003311_create_monthly_budgets.rb
class CreateMonthlyBudgets < ActiveRecord::Migration[7.1]
  def change
    return if table_exists?(:monthly_budgets)
    
    create_table :monthly_budgets do |t|
      t.references :user, null: false, foreign_key: { on_delete: :cascade }
      
      # e.g. "2025-12" — unique per user
      t.string :month_year, null: false

      # Total actual income assigned to this month (from income_events)
      t.decimal :total_actual_income, 
                precision: 12, scale: 2, 
                null: false, 
                default: "0.0"

      # Leftover / unassigned money (your "flex fund")
      t.decimal :flex_fund, 
                precision: 12, scale: 2, 
                null: false, 
                default: "0.0"

      # Optional: user can manually enter bank balance for "forgiving" check
      t.decimal :bank_balance, 
                precision: 12, scale: 2, 
                default: nil

      t.timestamps
    end

    # One budget per user per month (unique index provides fast lookup)
    unless index_exists?(:monthly_budgets, [:user_id, :month_year])
      add_index :monthly_budgets, [:user_id, :month_year], unique: true
    end
  end
end

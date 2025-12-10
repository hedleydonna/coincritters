# db/migrate/20251210000000_create_income_events.rb
class CreateIncomeEvents < ActiveRecord::Migration[7.1]
  def change
    create_table :income_events do |t|
      t.references :user, null: false, foreign_key: { on_delete: :cascade }
      t.references :income, foreign_key: { on_delete: :cascade } # optional → no null: false

      # This is the ONLY income type field — plain string
      t.string :income_type, null: false, default: "Paycheck"

      t.string :month_year, null: false
      t.string :assigned_month_year # optional carry-forward
      t.date   :received_on, null: false
      t.decimal :actual_amount, precision: 12, scale: 2, null: false, default: "0.0"
      t.text   :notes

      t.timestamps
    end

    # Indexes for fast monthly totals and carry-forward
    add_index :income_events, [:user_id, :month_year]
    add_index :income_events, [:user_id, :assigned_month_year], name: "index_income_events_on_assigned_month"
    add_index :income_events, [:income_id, :month_year]
  end
end

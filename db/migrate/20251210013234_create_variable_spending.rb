# db/migrate/20251210030000_create_variable_spending.rb
class CreateVariableSpending < ActiveRecord::Migration[7.1]
  def change
    create_table :variable_spending do |t|
      t.references :envelope, null: false, foreign_key: { on_delete: :cascade }

      # This matches the envelope's spending_group_name (e.g. "Groceries")
      t.string :spending_group_name, null: false

      t.decimal :amount, 
                precision: 12, scale: 2, 
                null: false, 
                default: "0.0"

      t.date :spent_on, null: false
      t.text :notes

      t.timestamps
    end

    # Fast lookup by envelope + date
    add_index :variable_spending, [:envelope_id, :spent_on]
    add_index :variable_spending, [:envelope_id, :spending_group_name]
  end
end

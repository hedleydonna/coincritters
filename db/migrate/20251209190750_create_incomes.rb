# db/migrate/20251209xxxxxx_create_incomes.rb
class CreateIncomes < ActiveRecord::Migration[7.1]
  def change
    create_table :incomes do |t|
      t.references :user, null: false, foreign_key: { on_delete: :cascade }
      t.string     :name, null: false
      t.string     :frequency, null: false, default: "monthly"
      t.decimal    :estimated_amount, precision: 12, scale: 2, null: false, default: "0.0"
      t.boolean    :active, null: false, default: true

      t.timestamps
    end

    # Prevent duplicate income names per user (e.g. two "Salary"Salary entries)
    add_index :incomes, [:user_id, :name], unique: true

    # Fast lookup for active incomes only
    add_index :incomes, [:user_id, :active]
  end
end

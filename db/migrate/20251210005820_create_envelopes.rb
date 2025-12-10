# db/migrate/20251210020000_create_envelopes.rb
class CreateEnvelopes < ActiveRecord::Migration[7.1]
  def change
    create_table :envelopes do |t|
      t.references :monthly_budget, null: false, foreign_key: { on_delete: :cascade }

      # This is the user-typed label — e.g. "Groceries", "Therapy", "OnlyFans"
      t.string :spending_group_name, null: false

      # 0 = fixed (rent, Netflix), 1 = variable (food, fun)
      t.integer :group_type, null: false, default: 1

      # true = savings pot (emergency fund, vacation, etc.)
      t.boolean :is_savings, null: false, default: false

      # How much the user assigned to this envelope this month
      t.decimal :allotted_amount, 
                precision: 12, scale: 2, 
                null: false, 
                default: "0.0"

      # How much has been spent from this envelope (updated live)
      t.decimal :spent_amount, 
                precision: 12, scale: 2, 
                null: false, 
                default: "0.0"

      t.timestamps
    end

    # One envelope name per budget month (e.g. only one "Rent" in Dec 2025)
    add_index :envelopes, [:monthly_budget_id, :spending_group_name], 
              unique: true, 
              name: "index_envelopes_on_budget_and_name"
  end
end

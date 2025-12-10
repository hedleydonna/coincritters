class CreateSpendingCategories < ActiveRecord::Migration[7.1]
  def change
    create_table :spending_categories do |t|
      t.references :user, null: false, foreign_key: { on_delete: :cascade }
      
      # Category name (e.g. "Rent", "Groceries", "Emergency Fund")
      t.string :name, null: false
      
      # 0 = fixed (rent, Netflix), 1 = variable (food, fun)
      t.integer :group_type, null: false, default: 1
      
      # true = savings pot (emergency fund, vacation, etc.)
      t.boolean :is_savings, null: false, default: false
      
      # Default amount to allocate when creating envelopes
      t.decimal :default_amount, 
                precision: 12, scale: 2, 
                default: "0.0"
      
      # Automatically create envelope in monthly budgets
      t.boolean :auto_create, null: false, default: true

      t.timestamps
    end

    # Ensure unique category names per user
    add_index :spending_categories, [:user_id, :name], unique: true
    add_index :spending_categories, [:user_id, :group_type]
  end
end

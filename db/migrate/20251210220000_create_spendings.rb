class CreateSpendings < ActiveRecord::Migration[7.1]
  def change
    create_table :spendings do |t|
      t.references :envelope, null: false, foreign_key: { on_delete: :cascade }
      
      t.decimal :amount, 
                precision: 12, scale: 2, 
                null: false, 
                default: "0.0"
      
      t.date :spent_on, null: false
      t.text :notes

      t.timestamps
    end

    # Fast lookup by envelope + date
    # Note: envelope_id index is automatically created by t.references
    add_index :spendings, [:envelope_id, :spent_on]
  end
end


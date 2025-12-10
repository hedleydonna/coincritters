class CreateBillPayments < ActiveRecord::Migration[7.1]
  def change
    create_table :bill_payments do |t|
      t.references :envelope, null: false, foreign_key: { on_delete: :cascade }

      t.decimal :actual_paid_amount, 
                precision: 12, scale: 2, 
                null: false, 
                default: "0.0"

      t.date :paid_on, null: false
      t.text :notes

      t.timestamps
    end

    # Fast lookup by envelope + date
    add_index :bill_payments, [:envelope_id, :paid_on]
  end
end


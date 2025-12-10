class DropVariableSpendingAndBillPayments < ActiveRecord::Migration[7.1]
  def change
    # Drop foreign keys first
    remove_foreign_key :variable_spending, :envelopes if foreign_key_exists?(:variable_spending, :envelopes)
    remove_foreign_key :bill_payments, :envelopes if foreign_key_exists?(:bill_payments, :envelopes)
    
    # Drop tables
    drop_table :variable_spending, if_exists: true
    drop_table :bill_payments, if_exists: true
  end
end


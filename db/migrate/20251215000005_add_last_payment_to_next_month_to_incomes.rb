class AddLastPaymentToNextMonthToIncomes < ActiveRecord::Migration[7.1]
  def change
    add_column :incomes, :last_payment_to_next_month, :boolean, default: false, null: false
  end
end


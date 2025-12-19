class AddExpectedOnToExpenses < ActiveRecord::Migration[7.1]
  def change
    add_column :expenses, :expected_on, :date
  end
end

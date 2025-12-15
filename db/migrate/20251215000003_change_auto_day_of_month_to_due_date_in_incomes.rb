class ChangeAutoDayOfMonthToDueDateInIncomes < ActiveRecord::Migration[7.1]
  def change
    # Remove auto_day_of_month column
    remove_column :incomes, :auto_day_of_month, :integer
    
    # Add due_date column (date field)
    add_column :incomes, :due_date, :date
  end
end


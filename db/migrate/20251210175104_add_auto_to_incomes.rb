# db/migrate/20251210xxxxxx_add_auto_to_incomes.rb
class AddAutoToIncomes < ActiveRecord::Migration[7.1]
  def change
    add_column :incomes, :auto_create, :boolean, null: false, default: false
    add_column :incomes, :auto_day_of_month, :integer  # 1-31, or nil = end of month
  end
end

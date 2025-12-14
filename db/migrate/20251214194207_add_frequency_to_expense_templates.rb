class AddFrequencyToExpenseTemplates < ActiveRecord::Migration[7.1]
  def change
    add_column :expense_templates, :frequency, :string, default: "monthly"
    add_column :expense_templates, :due_date, :date
  end
end

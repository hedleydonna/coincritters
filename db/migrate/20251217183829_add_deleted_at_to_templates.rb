class AddDeletedAtToTemplates < ActiveRecord::Migration[7.1]
  def change
    add_column :expense_templates, :deleted_at, :datetime
    add_column :income_templates, :deleted_at, :datetime
    add_index :expense_templates, :deleted_at
    add_index :income_templates, :deleted_at
  end
end

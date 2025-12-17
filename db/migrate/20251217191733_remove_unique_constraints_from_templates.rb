class RemoveUniqueConstraintsFromTemplates < ActiveRecord::Migration[7.1]
  def change
    # Remove unique constraint from expense_templates
    # Allow duplicate names (model validation ensures uniqueness among active records only)
    remove_index :expense_templates, name: "index_expense_templates_on_user_id_and_name"
    add_index :expense_templates, [:user_id, :name], name: "index_expense_templates_on_user_id_and_name"
    
    # Remove unique constraint from income_templates
    # Allow duplicate names (model validation ensures uniqueness among active records only)
    remove_index :income_templates, name: "index_income_templates_on_user_id_and_name"
    add_index :income_templates, [:user_id, :name], name: "index_income_templates_on_user_id_and_name"
  end
end

class RenameIncomesToIncomeTemplates < ActiveRecord::Migration[7.1]
  def change
    rename_table :incomes, :income_templates
    
    # Update foreign key in income_events table
    # Note: PostgreSQL automatically renames indexes when columns are renamed
    rename_column :income_events, :income_id, :income_template_id
    
    # Indexes are automatically renamed by PostgreSQL, but verify they exist
    # If they don't exist (shouldn't happen), create them
    unless index_exists?(:income_events, :income_template_id, name: "index_income_events_on_income_template_id")
      add_index :income_events, :income_template_id, name: "index_income_events_on_income_template_id"
    end
    
    unless index_exists?(:income_events, [:income_template_id, :month_year], name: "index_income_events_on_income_template_id_and_month_year")
      add_index :income_events, [:income_template_id, :month_year], name: "index_income_events_on_income_template_id_and_month_year"
    end
    
    # Update indexes on income_templates table (renamed from incomes)
    # PostgreSQL automatically renames indexes when tables are renamed, but we need to rename them explicitly
    # Remove old indexes if they exist
    if index_exists?(:income_templates, :user_id, name: "index_incomes_on_user_id")
      remove_index :income_templates, name: "index_incomes_on_user_id"
    end
    if index_exists?(:income_templates, [:user_id, :name], name: "index_incomes_on_user_id_and_name")
      remove_index :income_templates, name: "index_incomes_on_user_id_and_name"
    end
    if index_exists?(:income_templates, [:user_id, :active], name: "index_incomes_on_user_id_and_active")
      remove_index :income_templates, name: "index_incomes_on_user_id_and_active"
    end
    
    # Add new indexes only if they don't already exist
    unless index_exists?(:income_templates, :user_id, name: "index_income_templates_on_user_id")
      add_index :income_templates, :user_id, name: "index_income_templates_on_user_id"
    end
    unless index_exists?(:income_templates, [:user_id, :name], name: "index_income_templates_on_user_id_and_name")
      add_index :income_templates, [:user_id, :name], unique: true, name: "index_income_templates_on_user_id_and_name"
    end
    unless index_exists?(:income_templates, [:user_id, :active], name: "index_income_templates_on_user_id_and_active")
      add_index :income_templates, [:user_id, :active], name: "index_income_templates_on_user_id_and_active"
    end
  end
end


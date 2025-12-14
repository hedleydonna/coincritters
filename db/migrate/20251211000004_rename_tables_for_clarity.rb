class RenameTablesForClarity < ActiveRecord::Migration[7.1]
  def change
    # Rename tables - PostgreSQL will automatically rename indexes
    rename_table :envelope_templates, :expense_templates
    rename_table :envelopes, :expenses
    rename_table :spendings, :payments
    
    # Rename foreign key columns
    rename_column :expenses, :envelope_template_id, :expense_template_id
    rename_column :payments, :envelope_id, :expense_id
    
    # Note: Index names are automatically updated when tables are renamed.
    # Index names that reference column names (like envelope_template_id) will
    # still work correctly even though they contain the old column name in the index name.
    # Rails will regenerate the schema correctly after running db:schema:dump.
    # If you want to rename indexes to match new column names, you can do so in a
    # separate migration after verifying the actual index names in the database.
  end
end


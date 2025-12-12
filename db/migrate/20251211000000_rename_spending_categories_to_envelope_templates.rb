class RenameSpendingCategoriesToEnvelopeTemplates < ActiveRecord::Migration[7.1]
  def up
    # Rename the table (PostgreSQL automatically renames indexes when you rename a table)
    # Check if table still needs renaming
    unless table_exists?(:envelope_templates)
      rename_table :spending_categories, :envelope_templates
    end
    
    # Rename the foreign key column in envelopes (check if already renamed)
    if column_exists?(:envelopes, :spending_category_id)
      rename_column :envelopes, :spending_category_id, :envelope_template_id
    end
    
    # PostgreSQL automatically renames indexes when you rename a table.
    # Check and rename indexes on envelope_templates only if old names still exist
    execute <<-SQL
      DO $$
      BEGIN
        -- Rename user_id index if old name exists
        IF EXISTS (SELECT 1 FROM pg_indexes WHERE tablename = 'envelope_templates' AND indexname = 'index_spending_categories_on_user_id') THEN
          ALTER INDEX "index_spending_categories_on_user_id" RENAME TO "index_envelope_templates_on_user_id";
        END IF;
        
        -- Rename user_id_and_name index if old name exists
        IF EXISTS (SELECT 1 FROM pg_indexes WHERE tablename = 'envelope_templates' AND indexname = 'index_spending_categories_on_user_id_and_name') THEN
          ALTER INDEX "index_spending_categories_on_user_id_and_name" RENAME TO "index_envelope_templates_on_user_id_and_name";
        END IF;
        
        -- Rename user_id_and_group_type index if old name exists
        IF EXISTS (SELECT 1 FROM pg_indexes WHERE tablename = 'envelope_templates' AND indexname = 'index_spending_categories_on_user_id_and_group_type') THEN
          ALTER INDEX "index_spending_categories_on_user_id_and_group_type" RENAME TO "index_envelope_templates_on_user_id_and_group_type";
        END IF;
      END $$;
    SQL
    
    # Rename foreign key index in envelopes (check if old name exists)
    if index_exists?(:envelopes, :envelope_template_id, name: 'index_envelopes_on_spending_category_id')
      rename_index :envelopes,
                   'index_envelopes_on_spending_category_id',
                   'index_envelopes_on_envelope_template_id'
    end
    
    # Rename composite index in envelopes (check if old name exists)
    if index_exists?(:envelopes, [:monthly_budget_id, :envelope_template_id], name: 'index_envelopes_on_budget_and_spending_category')
      rename_index :envelopes,
                   'index_envelopes_on_budget_and_spending_category',
                   'index_envelopes_on_budget_and_envelope_template'
    end
    
    # Update foreign key constraint
    if foreign_key_exists?(:envelopes, :spending_categories)
      remove_foreign_key :envelopes, :spending_categories
    end
    unless foreign_key_exists?(:envelopes, :envelope_templates)
      add_foreign_key :envelopes, :envelope_templates, on_delete: :cascade
    end
    
    # Ensure foreign key constraint on envelope_templates exists
    unless foreign_key_exists?(:envelope_templates, :users)
      add_foreign_key :envelope_templates, :users, on_delete: :cascade
    end
  end
  
  def down
    # Reverse the changes
    remove_foreign_key :envelopes, :envelope_templates
    add_foreign_key :envelopes, :spending_categories, on_delete: :cascade
    
    if index_exists?(:envelopes, :envelope_template_id, name: 'index_envelopes_on_envelope_template_id')
      rename_index :envelopes, 'index_envelopes_on_envelope_template_id', 'index_envelopes_on_spending_category_id'
    end
    
    if index_exists?(:envelopes, [:monthly_budget_id, :envelope_template_id], name: 'index_envelopes_on_budget_and_envelope_template')
      rename_index :envelopes, 'index_envelopes_on_budget_and_envelope_template', 'index_envelopes_on_budget_and_spending_category'
    end
    
    rename_column :envelopes, :envelope_template_id, :spending_category_id
    
    rename_table :envelope_templates, :spending_categories
  end
end


class ReplaceAssignedMonthYearWithApplyToNextMonth < ActiveRecord::Migration[7.1]
  def up
    # Remove index if it exists
    if index_exists?(:income_events, [:user_id, :assigned_month_year], name: "index_income_events_on_assigned_month")
      remove_index :income_events, name: "index_income_events_on_assigned_month"
    end
    
    # Remove assigned_month_year column
    remove_column :income_events, :assigned_month_year, :string if column_exists?(:income_events, :assigned_month_year)
    
    # Add apply_to_next_month boolean
    add_column :income_events, :apply_to_next_month, :boolean, default: false, null: false unless column_exists?(:income_events, :apply_to_next_month)
    
    # Add index for querying
    add_index :income_events, [:user_id, :apply_to_next_month], name: "index_income_events_on_apply_to_next_month" unless index_exists?(:income_events, [:user_id, :apply_to_next_month], name: "index_income_events_on_apply_to_next_month")
  end

  def down
    # Remove new index
    remove_index :income_events, name: "index_income_events_on_apply_to_next_month" if index_exists?(:income_events, [:user_id, :apply_to_next_month], name: "index_income_events_on_apply_to_next_month")
    
    # Remove apply_to_next_month column
    remove_column :income_events, :apply_to_next_month, :boolean if column_exists?(:income_events, :apply_to_next_month)
    
    # Restore assigned_month_year column
    add_column :income_events, :assigned_month_year, :string unless column_exists?(:income_events, :assigned_month_year)
    
    # Restore index
    add_index :income_events, [:user_id, :assigned_month_year], name: "index_income_events_on_assigned_month" unless index_exists?(:income_events, [:user_id, :assigned_month_year], name: "index_income_events_on_assigned_month")
  end
end


class AddOverrideFieldsToEnvelopes < ActiveRecord::Migration[7.1]
  def change
    # Add name override field - allows envelopes to customize name per month
    # If null, the envelope will use the template's name
    add_column :envelopes, :name, :string, null: true
    
    # Add index for name lookups (when using override)
    add_index :envelopes, [:monthly_budget_id, :name], 
              name: 'index_envelopes_on_budget_and_name_override'
  end
end


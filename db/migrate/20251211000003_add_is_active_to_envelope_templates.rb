class AddIsActiveToEnvelopeTemplates < ActiveRecord::Migration[7.1]
  def change
    add_column :envelope_templates, :is_active, :boolean, default: true, null: false
    add_index :envelope_templates, :is_active
  end
end


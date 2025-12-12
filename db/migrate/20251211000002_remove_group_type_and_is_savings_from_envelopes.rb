class RemoveGroupTypeAndIsSavingsFromEnvelopes < ActiveRecord::Migration[7.1]
  def change
    # Remove override fields that are no longer needed
    # group_type and is_savings now always come from the envelope_template
    remove_column :envelopes, :group_type, :integer
    remove_column :envelopes, :is_savings, :boolean
  end
end


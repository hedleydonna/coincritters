class RemoveGroupTypeAndIsSavingsFromEnvelopes < ActiveRecord::Migration[7.1]
  def change
    # Remove override fields that are no longer needed
    # group_type and is_savings now always come from the envelope_template
    # Note: These columns may have already been removed by a previous migration,
    # so we check for existence first to avoid errors in production
    remove_column :envelopes, :group_type, :integer if column_exists?(:envelopes, :group_type)
    remove_column :envelopes, :is_savings, :boolean if column_exists?(:envelopes, :is_savings)
  end
end


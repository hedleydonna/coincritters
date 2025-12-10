class MigrateSpendingDataToSpendings < ActiveRecord::Migration[7.1]
  def up
    # Migrate data from variable_spending table
    if table_exists?(:variable_spending)
      execute <<-SQL
        INSERT INTO spendings (envelope_id, amount, spent_on, notes, created_at, updated_at)
        SELECT envelope_id, amount, spent_on, notes, created_at, updated_at
        FROM variable_spending
      SQL
    end

    # Migrate data from bill_payments table
    if table_exists?(:bill_payments)
      execute <<-SQL
        INSERT INTO spendings (envelope_id, amount, spent_on, notes, created_at, updated_at)
        SELECT envelope_id, actual_paid_amount, paid_on, notes, created_at, updated_at
        FROM bill_payments
      SQL
    end
  end

  def down
    # This migration is not easily reversible as we don't know which records
    # came from which original table
    raise ActiveRecord::IrreversibleMigration
  end
end


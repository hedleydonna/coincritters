class IgnoreDuplicateUsersTableIfExists < ActiveRecord::Migration[7.1]
  def change
    # Do nothing — the users table already exists from a previous deploy
    # This prevents the PG::DuplicateTable error on Render
  end
end

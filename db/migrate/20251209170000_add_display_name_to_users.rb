class AddDisplayNameToUsers < ActiveRecord::Migration[7.1]
  def change
    unless column_exists?(:users, :display_name)
      add_column :users, :display_name, :string
    end
  end
end

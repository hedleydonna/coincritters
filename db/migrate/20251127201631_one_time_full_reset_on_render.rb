class OneTimeFullResetOnRender < ActiveRecord::Migration[7.1]
  def up
    # This drops the broken database and recreates it perfectly clean
    puts "=== RUNNING FULL DATABASE RESET ON RENDER ==="
    Rake::Task['db:drop'].invoke
    Rake::Task['db:create'].invoke
    Rake::Task['db:migrate'].invoke
    puts "=== DATABASE IS NOW PERFECTLY CLEAN ==="
  end

  def down
    # Nothing to undo – this only runs once
  end
end

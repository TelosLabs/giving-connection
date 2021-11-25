class AddSearchExtensions < ActiveRecord::Migration[6.1]
  def change
    execute <<-SQL
      CREATE EXTENSION IF NOT EXISTS fuzzystrmatch;
      CREATE EXTENSION IF NOT EXISTS pg_trgm;
    SQL
  end
end

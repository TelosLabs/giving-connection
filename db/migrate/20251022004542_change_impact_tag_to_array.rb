class ChangeImpactTagToArray < ActiveRecord::Migration[7.2]
  def up
    execute <<-SQL
      ALTER TABLE blogs 
      ALTER COLUMN impact_tag 
      TYPE text[] 
      USING CASE 
        WHEN impact_tag IS NULL THEN ARRAY[]::text[]
        ELSE ARRAY[impact_tag]::text[]
      END
    SQL
    
    change_column_default :blogs, :impact_tag, []
  end

  def down
    execute <<-SQL
      ALTER TABLE blogs 
      ALTER COLUMN impact_tag 
      TYPE varchar 
      USING impact_tag[1]
    SQL
    
    change_column_default :blogs, :impact_tag, nil
  end
end
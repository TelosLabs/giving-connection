class ChangeEndTimeNullConstraintOnEvents < ActiveRecord::Migration[6.1]
  def change
    change_column_null :events, :end_time, true
  end
end

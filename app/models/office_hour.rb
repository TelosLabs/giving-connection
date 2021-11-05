# == Schema Information
#
# Table name: office_hours
#
#  id          :bigint           not null, primary key
#  day         :string           not null
#  open_time   :time
#  close_time  :time
#  closed      :boolean          default(FALSE)
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#  location_id :bigint
#
class OfficeHour < ActiveRecord::Base
  belongs_to :location
end

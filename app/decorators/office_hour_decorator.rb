class OfficeHourDecorator < ApplicationDecorator
  decorates_association :location
  delegate_all

  def local_open_time
    formatted_open_time&.strftime("%l:%M %p")
  end

  def local_close_time
    formatted_close_time&.strftime("%l:%M %p")
  end
end

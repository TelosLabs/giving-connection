class LocationDecorator < ApplicationDecorator
  delegate_all

  # Define presentation-specific methods here. Helpers are accessed through
  # `helpers` (aka `h`). You can override attributes, for example:
  #
  #   def created_at
  #     helpers.content_tag :span, class: 'time' do
  #       object.created_at.strftime("%a %m/%d/%y")
  #     end
  #   end

  def closed_office_hours_display
    next_opened_day = object.next_open_office_hours
    return "" unless next_opened_day

    if object.open_same_day?(next_opened_day)
      "Opens at #{next_opened_day.open_time.strftime("%l %p")}"
    else
      "Opens on #{object.next_open_day} at #{next_opened_day.open_time.strftime("%l %p")}"
    end
  end

  def working_hours
    "#{open_time_for_display} - #{close_time_for_display}"
  end

  def open_time_for_display
    object.office_hours.find_by(day: Time::DAYS_INTO_WEEK[:monday]).formatted_open_time.strftime("%l %p")
  end

  def close_time_for_display
    object.office_hours.find_by(day: Time::DAYS_INTO_WEEK[:monday]).formatted_close_time.strftime("%l %p")
  end
end

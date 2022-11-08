module LeftPopup
  class Component < ViewComponent::Base
    def initialize(results:, options: {}, current_user: false)
      @results = results
      @options = options
      @current_user = current_user
    end

    def display_day_working_hours(office_hour)
      return "Closed" if office_hour.closed?
      "#{office_hour.open_time.strftime("%l %p")}-#{office_hour.close_time.strftime("%l %p")} (CST)"
    end
  end
end

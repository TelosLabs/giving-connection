# frozen_string_literal: true

# rubocop:disable Style/ClassAndModuleChildren
# rubocop:disable Lint/MissingSuper
# rubocop:disable Style/Documentation
module WorkingHours
  class WorkingHours::Component < ViewComponent::Base
    def initialize(result:)
      @result = result
    end

    def display_day_working_hours(office_hour)
      return 'Closed' if office_hour.closed?

      "#{office_hour.open_time.strftime('%l %p')}-#{office_hour.close_time.strftime('%l %p')} (CST)"
    end
  end
end

# rubocop:enable Style/ClassAndModuleChildren
# rubocop:enable Lint/MissingSuper
# rubocop:enable Style/Documentation

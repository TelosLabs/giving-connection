# frozen_string_literal: true
module WorkingHours
  class WorkingHours::Component < ViewComponent::Base
    def initialize(result:)
      @result = result
    end
  end
end

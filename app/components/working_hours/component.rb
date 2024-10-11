# frozen_string_literal: true

module WorkingHours
  class WorkingHours::Component < ApplicationViewComponent
    def initialize(result:)
      @result = result
    end
  end
end

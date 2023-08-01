# frozen_string_literal: true
module WorkingHours
  class WorkingHours::Component < ApplicationViewComponent
    def initialize(result:, device:)
      @result = result
      @device = device
    end
  end
end

# frozen_string_literal: true
module MapLeftPopup
  class Component < ApplicationViewComponent
    def initialize(result:, current_user: false, device:)
      @result = result
      @current_user = current_user
      @device = device
    end
  end
end

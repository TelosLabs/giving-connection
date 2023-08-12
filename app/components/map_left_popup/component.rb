# frozen_string_literal: true
module MapLeftPopup
  class Component < ApplicationViewComponent
    def initialize(result:, current_user: false)
      @result = result
      @current_user = current_user
    end
  end
end

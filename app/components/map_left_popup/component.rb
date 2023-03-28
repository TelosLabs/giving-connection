# frozen_string_literal: true
module MapLeftPopup
  class Component < ViewComponent::Base
    def initialize(result:, options: {}, current_user: false)
      @result = result
      @options = options
      @current_user = current_user
    end
  end
end

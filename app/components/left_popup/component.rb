module LeftPopup
  class Component < ViewComponent::Base
    def initialize(results:, options: {}, current_user: false)
      @results = results
      @options = options
      @current_user = current_user
    end
  end
end

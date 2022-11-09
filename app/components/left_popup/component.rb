# frozen_string_literal: true

# left popup view component
# rubocop:disable Lint/MissingSuper
# rubocop:disable Style/Documentation

module LeftPopup
  class Component < ViewComponent::Base
    def initialize(results:, options: {}, current_user: false)
      @results = results
      @options = options
      @current_user = current_user
    end
  end
end

# rubocop:enable Lint/MissingSuper
# rubocop:enable Style/Documentation

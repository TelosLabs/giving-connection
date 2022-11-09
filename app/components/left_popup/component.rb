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

    def website_url
      uri = URI(@website)

      if uri.instance_of?(URI::Generic)
        split = uri.to_s.split('/')
        if split.size > 1
          uri = URI::HTTP.build({host: split.shift, path: '/'+split.join('/')})
        else
          uri = URI::HTTP.build({host: split.shift.to_s})
        end
      end
      uri.to_s
    end
  end
end

# rubocop:enable Lint/MissingSuper
# rubocop:enable Style/Documentation

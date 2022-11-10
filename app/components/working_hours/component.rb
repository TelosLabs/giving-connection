# frozen_string_literal: true

# rubocop:disable Style/ClassAndModuleChildren
# rubocop:disable Lint/MissingSuper
# rubocop:disable Style/Documentation
module WorkingHours
  class WorkingHours::Component < ViewComponent::Base
    def initialize(result:)
      @result = result
    end
  end
end

# rubocop:enable Style/ClassAndModuleChildren
# rubocop:enable Lint/MissingSuper
# rubocop:enable Style/Documentation

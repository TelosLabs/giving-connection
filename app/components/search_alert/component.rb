# frozen_string_literal: true

# navbar view component
# rubocop:disable Style/ClassAndModuleChildren
# rubocop:disable Lint/MissingSuper
class SearchAlert::Component < ViewComponent::Base
  def initialize(keywords: nil, filters: nil)
    @keywords = keywords
    @filters = filters.join(', ')
  end
end

# rubocop:enable Style/ClassAndModuleChildren
# rubocop:enable Lint/MissingSuper

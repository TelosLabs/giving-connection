# frozen_string_literal: true

# Search alert modal view component
# rubocop:disable Style/ClassAndModuleChildren
# rubocop:disable Lint/MissingSuper
class SearchAlert::Component < ViewComponent::Base
  def initialize(keywords: nil, filters: nil, edit: false, alert_id: nil)
    @keywords = keywords
    @filters = filters.join(', ')
    @edit = edit
    @alert_id = alert_id
  end

  def check_frequency(frequency)
    Alert.find(@alert_id).frequency == frequency
  end
end

# rubocop:enable Style/ClassAndModuleChildren
# rubocop:enable Lint/MissingSuper

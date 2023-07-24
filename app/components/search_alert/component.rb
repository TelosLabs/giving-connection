# frozen_string_literal: true

# Search alert modal view component
# rubocop:disable Style/ClassAndModuleChildren
# rubocop:disable Lint/MissingSuper
class SearchAlert::Component < ApplicationViewComponent
  def initialize(keywords: nil, filters: nil, edit: false, alert_id: nil)
    @keywords = keywords
    @filters = filters.join(', ')
    @edit = edit
    @alert_id = alert_id
    @copy = set_copy
  end

  def check_frequency(frequency)
    @edit ? Alert.find(@alert_id).frequency == frequency : 'weekly' == frequency
  end

  def set_copy
    @edit ? 'Save' : 'Create Alert'
  end

  def options
    {
      class:'c-button',
      type: 'button',
      data: { action: @edit ? 'click->modal#close click->search--alerts#editForm'
                            : 'click->modal#close click->search--alerts#submitForm',
              'search--alerts-target': @edit ? 'editButton' : '',
              'alert-id': @alert_id
            }
    }
  end
end

# rubocop:enable Style/ClassAndModuleChildren
# rubocop:enable Lint/MissingSuper

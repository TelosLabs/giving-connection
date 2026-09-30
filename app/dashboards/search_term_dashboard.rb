# frozen_string_literal: true

require "administrate/base_dashboard"

class SearchTermDashboard < Administrate::BaseDashboard
  # ATTRIBUTE_TYPES
  # a hash that describes the type of each of the model's fields.
  ATTRIBUTE_TYPES = {
    id: Field::Number,
    keyword: Field::String.with_options(searchable: true),
    normalized_keyword: Field::String.with_options(searchable: true),
    results_count: Field::Number,
    origin: Field::String,
    city: Field::String,
    state: Field::String,
    filtered: Field::Boolean,
    created_at: Field::DateTime,
    updated_at: Field::DateTime
  }.freeze

  # COLLECTION_ATTRIBUTES
  # an array of attributes that will be displayed on the model's index page
  # (and used as the columns of the CSV export).
  COLLECTION_ATTRIBUTES = %i[
    keyword
    results_count
    city
    state
    created_at
    filtered
  ].freeze

  # SHOW_PAGE_ATTRIBUTES
  # an array of attributes that will be displayed on the model's show page.
  SHOW_PAGE_ATTRIBUTES = %i[
    id
    keyword
    normalized_keyword
    results_count
    origin
    city
    state
    filtered
    created_at
    updated_at
  ].freeze

  # FORM_ATTRIBUTES
  # Search terms are recorded automatically from visitor searches and are only
  # ever viewed here — never created or edited from the admin.
  FORM_ATTRIBUTES = [].freeze

  # COLLECTION_FILTERS
  COLLECTION_FILTERS = {}.freeze

  # Overwrite this method to customize how search terms are displayed
  # across all pages of the admin dashboard.
  def display_resource(search_term)
    search_term.keyword
  end
end

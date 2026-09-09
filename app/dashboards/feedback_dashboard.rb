# frozen_string_literal: true

require "administrate/base_dashboard"

class FeedbackDashboard < Administrate::BaseDashboard
  # ATTRIBUTE_TYPES
  # a hash that describes the type of each of the model's fields.
  ATTRIBUTE_TYPES = {
    id: Field::Number,
    read: Field::Boolean,
    rating: Field::Number,
    category: Field::String,
    context: Field::String,
    comment: Field::Text.with_options(searchable: true),
    page_url: Field::String,
    email: Field::String.with_options(searchable: false),
    user: Field::BelongsTo,
    read_at: Field::DateTime,
    created_at: Field::DateTime,
    updated_at: Field::DateTime
  }.freeze

  # COLLECTION_ATTRIBUTES
  # an array of attributes that will be displayed on the model's index page
  # (and used as the columns of the CSV export).
  COLLECTION_ATTRIBUTES = %i[
    read
    created_at
    page_url
    rating
    category
    email
  ].freeze

  # SHOW_PAGE_ATTRIBUTES
  # an array of attributes that will be displayed on the model's show page.
  SHOW_PAGE_ATTRIBUTES = %i[
    id
    read
    read_at
    created_at
    context
    page_url
    rating
    category
    comment
    email
    user
  ].freeze

  # FORM_ATTRIBUTES
  # Feedback is user-generated and not editable from the admin; read state is
  # managed through the mark-as-read/unread actions.
  FORM_ATTRIBUTES = [].freeze

  # COLLECTION_FILTERS
  # Type "unread:" or "read:" in the search field to filter the inbox.
  COLLECTION_FILTERS = {
    unread: ->(resources) { resources.unread },
    read: ->(resources) { resources.read }
  }.freeze

  # Overwrite this method to customize how feedback records are displayed
  # across all pages of the admin dashboard.
  def display_resource(feedback)
    "Feedback ##{feedback.id}"
  end
end

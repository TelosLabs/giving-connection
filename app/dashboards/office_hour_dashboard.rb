# frozen_string_literal: true

require "administrate/base_dashboard"

class OfficeHourDashboard < Administrate::BaseDashboard
  # ATTRIBUTE_TYPES
  # a hash that describes the type of each of the model's fields.
  #
  # Each different type represents an Administrate::Field object,
  # which determines how the attribute is displayed
  # on pages throughout the dashboard.
  ATTRIBUTE_TYPES = {
    location: Field::BelongsTo,
    id: Field::Number,
    day: Field::Select.with_options(
      collection: Time::DAYS_INTO_WEEK
    ),
    day_name: Field::String,
    open_time: TimeSelectField,
    close_time: TimeSelectField,
    local_close_time: Field::String,
    local_open_time: Field::String,
    closed: Field::Boolean
  }.freeze

  # COLLECTION_ATTRIBUTES
  # an array of attributes that will be displayed on the model's index page.
  #
  # By default, it's limited to four items to reduce clutter on index pages.
  # Feel free to add, remove, or rearrange items.
  COLLECTION_ATTRIBUTES = %i[
    day_name
    local_open_time
    local_close_time
    closed
  ].freeze

  # SHOW_PAGE_ATTRIBUTES
  # an array of attributes that will be displayed on the model's show page.
  SHOW_PAGE_ATTRIBUTES = %i[
    id
    location
    day_name
    local_open_time
    local_close_time
    closed
  ].freeze

  # FORM_ATTRIBUTES
  # an array of attributes that will be displayed
  # on the model's form (`new` and `edit`) pages.
  FORM_ATTRIBUTES = %i[
    day
    open_time
    close_time
    closed
  ].freeze

  # COLLECTION_FILTERS
  # a hash that defines filters that can be used while searching via the search
  # field of the dashboard.
  #
  # For example to add an option to search for open resources by typing "open:"
  # in the search field:
  #
  #   COLLECTION_FILTERS = {
  #     open: ->(resources) { resources.where(open: true) }
  #   }.freeze
  COLLECTION_FILTERS = {}.freeze

  # Overwrite this method to customize how office hours are displayed
  # across all pages of the admin dashboard.
  #
  # def display_resource(office_hour)
  #   "OfficeHour ##{office_hour.id}"
  # end
end

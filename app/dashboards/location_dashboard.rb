# frozen_string_literal: true

require 'administrate/base_dashboard'

class LocationDashboard < Administrate::BaseDashboard
  # ATTRIBUTE_TYPES
  # a hash that describes the type of each of the model's fields.
  #
  # Each different type represents an Administrate::Field object,
  # which determines how the attribute is displayed
  # on pages throughout the dashboard.
  ATTRIBUTE_TYPES = {
    organization: Field::BelongsTo,
    name: Field::String,
    id: Field::Number,
    youtube_video_link: Field::String,
    images: Field::ActiveStorage.with_options( multiple: true ),
    latitude: HiddenField,
    longitude: HiddenField,
    lonlat: Field::String.with_options(searchable: false),
    email: Field::String,
    main: Field::Boolean,
    physical: Field::Boolean,
    offer_services: Field::Boolean,
    created_at: Field::DateTime,
    updated_at: Field::DateTime,
    address: AddressField,
    phone_number: Field::HasOne,
    office_hours: Field::NestedHasMany,
    location_services: Field::NestedHasMany,
    non_standard_office_hours: Field::Select.with_options(searchable: false, collection: -> (field) { field.resource.class.send(field.attribute.to_s.pluralize).keys }),
    services: Field::HasMany,
    po_box: Field::Boolean,
    public_address: Field::Boolean,
    suite: Field::String
  }.freeze

  # COLLECTION_ATTRIBUTES
  # an array of attributes that will be displayed on the model's index page.
  #
  # By default, it's limited to four items to reduce clutter on index pages.
  # Feel free to add, remove, or rearrange items.
  COLLECTION_ATTRIBUTES = %i[
    id
    name
    address
    main
    non_standard_office_hours
    organization
  ].freeze

  # SHOW_PAGE_ATTRIBUTES
  # an array of attributes that will be displayed on the model's show page.
  SHOW_PAGE_ATTRIBUTES = %i[
    id
    organization
    name
    services
    po_box
    public_address
    latitude
    longitude
    email
    main
    images
    physical
    offer_services
    address
    suite
    phone_number
    non_standard_office_hours
    office_hours
  ].freeze

  # FORM_ATTRIBUTES
  # an array of attributes that will be displayed
  # on the model's form (`new` and `edit`) pages.
  FORM_ATTRIBUTES = %i[
    name
    main
    youtube_video_link
    images
    physical
    non_standard_office_hours
    email
    phone_number
    po_box
    public_address
    address
    suite
    latitude
    longitude
    offer_services
    location_services
    office_hours
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

  # Overwrite this method to customize how locations are displayed
  # across all pages of the admin dashboard.
  #
  # def display_resource(location)
  #   "Location ##{location.id}"
  # end

  def display_resource(location)
    "#{location.address[0..20]}..."
  end
end

require "administrate/base_dashboard"

class OrganizationDashboard < Administrate::BaseDashboard
  # ATTRIBUTE_TYPES
  # a hash that describes the type of each of the model's fields.
  #
  # Each different type represents an Administrate::Field object,
  # which determines how the attribute is displayed
  # on pages throughout the dashboard.
  ATTRIBUTE_TYPES = {
    text_translations: Field::HasMany,
    created_by: Field::BelongsTo,
    id: Field::Number,
    name: Field::String,
    ein_number: Field::String,
    irs_ntee_code: Field::String,
    mission_statement: Field::Text,
    vision_statement: Field::Text,
    tagline: Field::Text,
    description: Field::Text,
    impact: Field::Text,
    website: Field::String,
    scope_of_working: Field::String,
    created_at: Field::DateTime,
    updated_at: Field::DateTime,
  }.freeze

  # COLLECTION_ATTRIBUTES
  # an array of attributes that will be displayed on the model's index page.
  #
  # By default, it's limited to four items to reduce clutter on index pages.
  # Feel free to add, remove, or rearrange items.
  COLLECTION_ATTRIBUTES = %i[
    id
    created_by
    name
    website
    ein_number
    irs_ntee_code  
  ].freeze

  # SHOW_PAGE_ATTRIBUTES
  # an array of attributes that will be displayed on the model's show page.
  SHOW_PAGE_ATTRIBUTES = %i[ 
    created_by
    id
    name
    ein_number
    irs_ntee_code
    mission_statement
    vision_statement
    tagline
    description
    impact
    website
    scope_of_working
    created_at
    updated_at
  ].freeze

  # FORM_ATTRIBUTES
  # an array of attributes that will be displayed
  # on the model's form (`new` and `edit`) pages.
  FORM_ATTRIBUTES = %i[
    created_by
    name
    ein_number
    irs_ntee_code
    mission_statement
    vision_statement
    tagline
    description
    impact
    website
    scope_of_working
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

  # Overwrite this method to customize how organizations are displayed
  # across all pages of the admin dashboard.
  #
  # def display_resource(organization)
  #   "Organization ##{organization.id}"
  # end
end

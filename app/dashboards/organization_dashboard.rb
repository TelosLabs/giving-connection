# frozen_string_literal: true

require "administrate/base_dashboard"

class OrganizationDashboard < Administrate::BaseDashboard
  # ATTRIBUTE_TYPES
  # a hash that describes the type of each of the model's fields.
  #
  # Each different type represents an Administrate::Field object,
  # which determines how the attribute is displayed
  # on pages throughout the dashboard.
  ATTRIBUTE_TYPES = {
    id: Field::Number,
    name: Field::String,
    second_name: Field::String,
    ein_number: UniquenessWarningField,
    irs_ntee_code: Field::SelectBasic.with_options({
      choices: Organization::NTEE_CODE
    }),
    website: Field::String,
    scope_of_work: Field::SelectBasic.with_options({
      choices: Organization::SCOPE
    }),
    created_at: Field::DateTime,
    updated_at: Field::DateTime,
    mission_statement_en: Field::Text,
    mission_statement_es: Field::Text,
    vision_statement_en: Field::Text,
    vision_statement_es: Field::Text,
    tagline_en: Field::Text,
    tagline_es: Field::Text,
    social_media: Field::HasOne,
    organization_beneficiaries: CheckboxField,
    logo: Field::ActiveStorage,
    tags: TagInputField,
    locations: Field::NestedHasMany,
    phone_number: Field::Text,
    email: Field::Text,
    active: Field::Boolean,
    verified: Field::Boolean,
    donation_link: Field::String,
    volunteer_link: Field::String,
    volunteer_availability: Field::Boolean,
    organization_causes: Field::NestedHasMany,
    general_population_serving: ToggleCheckField
  }.freeze

  # COLLECTION_ATTRIBUTES
  # an array of attributes that will be displayed on the model's index page.
  #
  # By default, it's limited to four items to reduce clutter on index pages.
  # Feel free to add, remove, or rearrange items.
  COLLECTION_ATTRIBUTES = %i[
    id
    name
    active
  ].freeze

  # SHOW_PAGE_ATTRIBUTES
  # an array of attributes that will be displayed on the model's show page.
  SHOW_PAGE_ATTRIBUTES = %i[
    logo
    active
    verified
    name
    second_name
    ein_number
    irs_ntee_code
    website
    scope_of_work
    created_at
    updated_at
    mission_statement_en
    vision_statement_en
    tagline_en
    mission_statement_es
    vision_statement_es
    tagline_es
    organization_beneficiaries
    general_population_serving
    tags
    donation_link
    volunteer_link
    volunteer_availability
    social_media
    locations
  ].freeze

  # FORM_ATTRIBUTES
  # an array of attributes that will be displayed
  # on the model's form (`new` and `edit`) pages.
  FORM_ATTRIBUTES = %i[
    logo
    active
    verified
    name
    second_name
    ein_number
    irs_ntee_code
    website
    scope_of_work
    mission_statement_en
    vision_statement_en
    tagline_en
    mission_statement_es
    vision_statement_es
    tagline_es
    organization_beneficiaries
    general_population_serving
    tags
    donation_link
    volunteer_availability
    volunteer_link
    organization_causes
    social_media
    locations
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
  def display_resource(organization)
    organization.name&.titleize
  end
end

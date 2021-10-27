# frozen_string_literal: true

require 'administrate/base_dashboard'

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
    ein_number: Field::String,
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
    description_en: Field::Text,
    description_es: Field::Text,
    social_media: Field::HasOne,
    service: Field::HasOne,
    categories: Field::HasMany,
    organization_beneficiaries: CheckboxField,
    logo: Field::ActiveStorage
  }.freeze

  # COLLECTION_ATTRIBUTES
  # an array of attributes that will be displayed on the model's index page.
  #
  # By default, it's limited to four items to reduce clutter on index pages.
  # Feel free to add, remove, or rearrange items.
  COLLECTION_ATTRIBUTES = %i[
    id
    name
    ein_number
  ].freeze

  # SHOW_PAGE_ATTRIBUTES
  # an array of attributes that will be displayed on the model's show page.
  SHOW_PAGE_ATTRIBUTES = %i[
    id
    name
    ein_number
    irs_ntee_code
    website
    scope_of_work
    created_at
    updated_at
    mission_statement_en
    vision_statement_en
    tagline_en
    description_en
    mission_statement_es
    vision_statement_es
    tagline_es
    description_es
    service
    categories
    organization_beneficiaries
    social_media
  ].freeze

  # FORM_ATTRIBUTES
  # an array of attributes that will be displayed
  # on the model's form (`new` and `edit`) pages.
  FORM_ATTRIBUTES = %i[
    logo
    name
    ein_number
    irs_ntee_code
    website
    scope_of_work
    mission_statement_en
    vision_statement_en
    tagline_en
    description_en
    mission_statement_es
    vision_statement_es
    tagline_es
    description_es
    service
    categories
    organization_beneficiaries
    social_media
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

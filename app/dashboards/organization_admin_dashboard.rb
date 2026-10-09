# frozen_string_literal: true

require "administrate/base_dashboard"

class OrganizationAdminDashboard < Administrate::BaseDashboard
  # ATTRIBUTE_TYPES
  # a hash that describes the type of each of the model's fields.
  #
  # Each different type represents an Administrate::Field object,
  # which determines how the attribute is displayed
  # on pages throughout the dashboard.
  ATTRIBUTE_TYPES = {
    # Organization has 5000+ rows. When we already know which one (arriving
    # from the organization's own show page via "Associate admin user", or
    # editing an existing record), scope the dropdown to just that one so the
    # form doesn't render 5000+ <option>s. Falls back to the full list only
    # for the rare direct-URL case where no organization is known yet.
    organization: Field::BelongsTo.with_options(scope: lambda { |field|
      org_id = field.resource&.organization_id
      org_id ? Organization.where(id: org_id) : Organization.all
    }),
    user: BelongsToSearchField,
    id: Field::Number,
    role: Field::Select.with_options({
      collection: ["admin"]
    }),
    created_at: Field::DateTime,
    updated_at: Field::DateTime
  }.freeze

  # COLLECTION_ATTRIBUTES
  # an array of attributes that will be displayed on the model's index page.
  #
  # By default, it's limited to four items to reduce clutter on index pages.
  # Feel free to add, remove, or rearrange items.
  COLLECTION_ATTRIBUTES = %i[
    organization
    user
    id
    role
  ].freeze

  # SHOW_PAGE_ATTRIBUTES
  # an array of attributes that will be displayed on the model's show page.
  SHOW_PAGE_ATTRIBUTES = %i[
    organization
    user
    id
    role
    created_at
    updated_at
  ].freeze

  # FORM_ATTRIBUTES
  # an array of attributes that will be displayed
  # on the model's form (`new` and `edit`) pages.
  FORM_ATTRIBUTES = %i[
    organization
    user
    role
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

  # Overwrite this method to customize how organization admins are displayed
  # across all pages of the admin dashboard.
  #
  # def display_resource(organization_admin)
  #   "OrganizationAdmin ##{organization_admin.id}"
  # end
end

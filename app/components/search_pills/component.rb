# frozen_string_literal: true

# search pills view component
# rubocop:disable Style/ClassAndModuleChildren
# rubocop:disable Lint/MissingSuper
class SearchPills::Component < ViewComponent::Base
  def initialize(causes:, services:, beneficiary_subcategories:, params:)
    @causes = causes
    @services = services
    @beneficiary_subcategories = beneficiary_subcategories
    @params = params
    @tabs_labels = ['Cause', 'Location', 'Services', 'Populations served', 'Hours']
    @radii_in_miles = [2, 5, 15, 30, 60, 180, "Any"]
  end

  def all_causes_checked?
    @causes.all? { |cause| @params.dig(:search, :causes)&.include?(cause.name) }
  end

  def all_services_checked?
    @services.all? { |service| @params.dig(:search, :services, service.cause.name)&.include?(service.name) }
  end

  def all_beneficiary_subcategories_checked?
    @beneficiary_subcategories.all? { |subcategory| @params.dig(:search, :beneficiary_groups, subcategory.beneficiary_group.name)&.include?(subcategory.name) }
  end

  def miles_to_km(miles)
    miles == "Any" ? 1_000_000 : (miles * 1.609344).round(3)
  end
end

# rubocop:enable Style/ClassAndModuleChildren
# rubocop:enable Lint/MissingSuper

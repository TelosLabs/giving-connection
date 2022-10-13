class SearchPills::Component < ViewComponent::Base
  def initialize(causes:, services:, beneficiary_subcategories:, params:)
    @causes = causes
    @services = services
    @beneficiary_subcategories = beneficiary_subcategories
    @params = params
    @tabs_labels = ['Cause', 'Location', 'Services', 'Populations served', 'Hours']
    @distances = [
      {
        kilometers: 3.21,
        miles: "2 mi"
      },
      {
        kilometers: 8.04,
        miles: "5 mi"
      },
      {
        kilometers: 24.1402,
        miles: "15 mi"
      },
      {
        kilometers: 48.2804,
        miles: "30 mi"
      },
      {
        kilometers: 96.5608,
        miles: "60 mi"
      },
      {
        kilometers: 289.6824,
        miles: "180 mi"
      },
      {
        kilometers: 1_000_000,
        miles: "Any"
      }
    ]
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
end

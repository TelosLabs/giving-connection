class SearchPills::Component < ViewComponent::Base
  def initialize(causes:, services:, beneficiary_subcategories:, params:, params_applied:, form:)
    @causes = causes
    @form = form
    @services = services
    @beneficiary_subcategories = beneficiary_subcategories
    @params = params
    @params_applied = params_applied
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
end

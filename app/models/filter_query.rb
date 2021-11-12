# frozen_string_literal: true

class FilterQuery

  attr_reader :locations

  def initialize(params={})
    @locations = Location.all
    @service_name = params[:services]
    @closed = params[:open_now] == 'true'
    @beneficiary_group = params[:beneficiary_groups]
    @city = params[:city]
    @state = params[:state]
  end

  def by_service
    @service_name.empty? ? @locations : @locations.joins(:services).where(services: {name: @service_name })
  end

  def by_location_and_service
    by_service.where("address ILIKE ? AND address ILIKE ?", "%#{@city}%", "%#{@state}%")
  end

  def search_by_filter
    query = <<-SQL
    SELECT * FROM locations
    JOIN organizations ON organizations.id = locations.organization_id
    JOIN organization_beneficiaries ON organization_beneficiaries.organization_id = organizations.id
    JOIN beneficiary_subcategories ON beneficiary_subcategories.id = organization_beneficiaries.beneficiary_subcategory_id
    JOIN beneficiary_groups ON beneficiary_groups.id = beneficiary_subcategories.beneficiary_group_id
    WHERE beneficiary_groups.name = '#{@beneficiary_group}'
    SQL
    @beneficiary_group.empty? ? by_location_and_service : by_location_and_service.find_by_sql(query)
  end

  def by_open_now
    @locations.joins(:office_hours).where(office_hours: {closed: @closed })
  end

end

class DesignationTag::Component < ApplicationViewComponent
  attr_reader :organization, :container_options, :designation_map

  def initialize(organization, container_options: {})
    @organization = organization.decorate
    @container_options = container_options
    build_designation_map
  end

  def container_setup
    setup = {class: "flex flex-wrap gap-2 mt-2"}
    
    setup.merge(container_options) do |_key, prev_value, new_value|
      "#{prev_value}  #{new_value}"
    end
  end

  private

  def build_designation_map
    @designation_map = {}

    if ["nationwide", "internationally"].include? organization.scope_of_work
      designation_map[organization.scope_of_work.capitalize] =
        "Services offered #{organization.scope_of_work}"
    end

    if organization.volunteer_availability
      designation_map["Volunteer"] = "Volunteer opportunities available"
    end
  end
end

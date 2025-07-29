module Admin
  class ExportLocationsController < Admin::ApplicationController
    def new
      # Get all locations with their associated organization data, maintaining original behavior
      locations = Location.includes(
        organization: [:causes, :beneficiary_subcategories, :tags, :social_media]
      ).order(:name)
      
      # Create a comprehensive export with all organization data
      file_path = LocationsExporter.call(locations, location_url(":id"))

      send_file(
        file_path,
        filename: "organizations-complete-data.xlsx",
        type: "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet",
        disposition: "attachment"
      )
    end
  end
end

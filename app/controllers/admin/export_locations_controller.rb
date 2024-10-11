module Admin
  class ExportLocationsController < Admin::ApplicationController
    def new
      locations = Location.order :name
      file_path = LocationsExporter.call(locations, location_url(":id"))

      send_file(
        file_path,
        filename: "nonprofits-data.xlsx",
        type: "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet",
        disposition: "attachment"
      )
    end
  end
end

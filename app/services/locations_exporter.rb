class LocationsExporter < ApplicationService
  def initialize(locations, link_pattern)
    @locations = locations
    @link_pattern = link_pattern
  end

  def call
    package = Axlsx::Package.new
    workbook = package.workbook

    workbook.add_worksheet(name: "Giving Connection Nonprofits") do |sheet|
      title_style = sheet.styles.add_style(bg_color: "FF0782D0", fg_color: "FFFFFFFF")
      sheet.add_row ["Name", "GC profile link"], style: title_style

      @locations.each do |location|
        sheet.add_row [location.name, format_link(location.id)]
      end
    end

    file_path = Rails.root.join('tmp', 'nonprofits-data.xlsx')
    package.serialize(file_path)

    file_path
  end

  private

  def format_link(id)
    location_id = id.to_s
    @link_pattern.gsub(":id", location_id)
  end
end

# LocationsExporter
# 
# This service exports comprehensive organization and location data to Excel format.
# It includes all organization fields, associated data, and location information.
# Note: This service has been enhanced to export all fields instead of just name and profile link.
#
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
      
      # Enhanced headers - original columns first, then all additional data
      headers = [
        "Name",  # Original column
        "GC profile link",  # Original column
        "Organization ID",
        "Organization Name", 
        "Second Name",
        "EIN Number",
        "IRS NTEE Code",
        "Website",
        "Scope of Work",
        "Mission Statement (EN)",
        "Mission Statement (ES)",
        "Vision Statement (EN)", 
        "Vision Statement (ES)",
        "Tagline (EN)",
        "Tagline (ES)",
        "Phone Number",
        "Email",
        "Active",
        "Verified",
        "Donation Link",
        "Volunteer Link",
        "Volunteer Availability",
        "General Population Serving",
        "Created At",
        "Updated At",
        "Causes",
        "Beneficiary Subcategories",
        "Tags",
        "Social Media - Facebook",
        "Social Media - Instagram", 
        "Social Media - Twitter",
        "Social Media - LinkedIn",
        "Social Media - YouTube",
        "Social Media - Blog",
        "Location ID",
        "Location Address",
        "Location Website",
        "Location Email",
        "Location Main",
        "Location Offer Services",
        "Location Suite",
        "Location PO Box",
        "Location Public Address",
        "Location Non-Standard Office Hours",
        "Location Time Zone",
        "Location YouTube Video Link",
        "Location Latitude",
        "Location Longitude",
        "Location Created At",
        "Location Updated At"
      ]
      
      sheet.add_row headers, style: title_style

      # Process each location individually (maintaining original order and count)
      @locations.each do |location|
        organization = location.organization
        next unless organization # Skip if no organization associated
        
        # Enhanced data - original columns first, then all additional data
        row_data = [
          location.name,  # Original column - location name
          format_link(location.id),  # Original column - profile link
          organization.id,
          organization.name,
          organization.second_name,
          organization.ein_number,
          organization.irs_ntee_code,
          organization.website,
          organization.scope_of_work,
          organization.mission_statement_en,
          organization.mission_statement_es,
          organization.vision_statement_en,
          organization.vision_statement_es,
          organization.tagline_en,
          organization.tagline_es,
          organization.phone_number,
          organization.email,
          organization.active,
          organization.verified,
          organization.donation_link,
          organization.volunteer_link,
          organization.volunteer_availability,
          organization.general_population_serving,
          organization.created_at,
          organization.updated_at,
          organization.causes.pluck(:name).join(", "),
          organization.beneficiary_subcategories.pluck(:name).join(", "),
          organization.tags.pluck(:name).join(", "),
          organization.social_media&.facebook,
          organization.social_media&.instagram,
          organization.social_media&.twitter,
          organization.social_media&.linkedin,
          organization.social_media&.youtube,
          organization.social_media&.blog,
          location.id,
          location.address,
          location.website,
          location.email,
          location.main,
          location.offer_services,
          location.suite,
          location.po_box,
          location.public_address,
          location.non_standard_office_hours,
          location.time_zone,
          location.youtube_video_link,
          location.latitude,
          location.longitude,
          location.created_at,
          location.updated_at
        ]
        
        sheet.add_row row_data
      end
    end

    file_path = Rails.root.join("tmp/nonprofits-data.xlsx")
    package.serialize(file_path)

    file_path
  end

  private

  def format_link(id)
    location_id = id.to_s
    @link_pattern.gsub(":id", location_id)
  end
end

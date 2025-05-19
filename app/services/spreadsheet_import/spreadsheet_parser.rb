module SpreadsheetImport
  class SpreadsheetParser
    ASSOCIATION_NAMES = ["orgs", "presets"].freeze

    def initialize(spreadsheet:, creator:)
      @spreadsheet = spreadsheet
      @creator = creator
      @file_path = File.open(Rails.root.join("db/uploads").to_s)
      @csv_file_paths = csv_file_paths
    end

    def call
      load_presets
      import
    end  

    private

    def csv_file_paths
      data_spreadsheet = Roo::Spreadsheet.open(@spreadsheet)
      
      missing_sheets = ASSOCIATION_NAMES - data_spreadsheet.sheets.map(&:to_s)
      if missing_sheets.any?
        raise "Missing required sheets: #{missing_sheets.join(', ')}"
      end

      ASSOCIATION_NAMES.each do |association_name|
        sheet_name = association_name.to_s
        data_spreadsheet.default_sheet = sheet_name
        data_spreadsheet.to_csv("#{@file_path.path}/#{sheet_name}.csv")
      end

      ASSOCIATION_NAMES.each_with_object({}) do |file_name, hash|
        hash[:"#{file_name}_csv_file"] = "#{@file_path.path}/#{file_name}.csv"
      end
    end

    def load_presets
      CSV.foreach(@csv_file_paths[:presets_csv_file], headers: :first_row) do |row|
        # Each cell can have a value or be blank. We'll skip blank ones and only import unique values.
    
        # 1. Causes
        cause = row["causes"]&.strip
        Cause.find_or_create_by!(name: cause) if cause.present?
    
        # 2. Beneficiaries
        beneficiary = row["beneficiaries"]&.strip
        BeneficiarySubcategory.find_or_create_by!(name: beneficiary) if beneficiary.present?
    
        # 3. Services
        service = row["services"]&.strip
        Service.find_or_create_by!(name: service) if service.present?
      end
    end
    
    
    def import
      total_import_results = {ids: [], failed_instances: []}
      organizations = create_models

      organizations.each do |org|
        org_import_result = Organization.import([org], recursive: true, track_validation_failures: true)
        if org_import_result&.ids&.any?
          org.run_callbacks(:create) { true }
          total_import_results[:ids] << org_import_result.ids.first
        else
          total_import_results[:failed_instances] += org_import_result&.failed_instances
        end
      end
      total_import_results
    end

    def create_models
      organizations = []
      CSV.foreach(@csv_file_paths[:orgs_csv_file], headers: :first_row) do |org_row|
        begin
          next if organization_already_exists?(org_row["Organization Name"])
          new_organization = Organization.new(build_organization_hash(org_row))

          next unless new_organization
          new_organization.build_social_media(build_social_media_hash(org_row))
          build_location_from_org_row(new_organization, org_row)
          build_org_associations(new_organization, org_row)

          organizations << new_organization
        rescue => e
          Rails.logger.error("Failed to parse organization row #{index}: #{e.message}")
        end
      end
      organizations
    end

    def organization_already_exists?(org_name)
      Organization.unscoped.exists?(name: org_name)
    end
    
    def build_organization_hash(org_row)      
      {
        name: org_row["Organization Name"],
        ein_number: org_row["EIN Number"],
        irs_ntee_code: org_row["IRS NTEE Code"],
        mission_statement_en: org_row["Mission Statement - What We Do"],
        vision_statement_en: org_row["Vision - Goals and Aspirations"],
        tagline_en: org_row["Services - How We Do It"],
        mission_statement_es: nil,
        vision_statement_es: nil,
        tagline_es: nil,
        website: org_row["Website link"],
        donation_link: org_row["Donation link"],
        scope_of_work: org_row["Scope of Work"],
        creator: @creator,
        active: true
      }
    end

    def build_social_media_hash(org_row)
      {
        facebook: org_row["Facebook"],
        instagram: org_row["Instagram"],
        twitter: org_row["Twitter/X"],
        linkedin: org_row["LinkedIn"],
        youtube: org_row["YouTube"],
        blog: org_row["Blog"]
      }
    end

    def build_location_from_org_row(organization, org_row)
      geo_result = SpreadsheetImport::AddressLocationParser.new(org_row["Address"]).call
      timezone = SpreadsheetImport::TimezoneDetection.new(org_row["Address"]).call

      location = organization.locations.build(
        name: "Main Location",
        address: org_row["Address"],
        email: org_row["Email"],
        time_zone: timezone,
        offer_services: true,
        non_standard_office_hours: org_row["Hours of Operation"],
        youtube_video_link: org_row["YouTube Video Link"],
        website: org_row["Website link"],
        latitude: geo_result&.latitude,
        longitude: geo_result&.longitude
      )
    
      phone_number = org_row["Phone"]
      location.build_phone_number(number: phone_number, main: true) if phone_number.present?
    
      services = (org_row["Services"] || "").split(",").map(&:strip)
      services.each do |service_name|
        service = Service.find_by(name: service_name)
        location.location_services.build(service: service) if service
      end
    
      hours_string = org_row["Detailed Hours Of Operation"]
      if hours_string.present?
        office_hours = SpreadsheetImport::OfficeHoursParser.new(hours_string).call
      end
    end

    def build_org_associations(org, org_row)
      (org_row["Causes"] || "").split(",").map(&:strip).each do |cause_name|
        cause = Cause.find_by(name: cause_name)
        org.organization_causes.build(cause: cause) if cause
      end
    
      (org_row["Populations Served"] || "").split(",").map(&:strip).each do |ben_name|
        beneficiary = BeneficiarySubcategory.find_by(name: ben_name)
        org.organization_beneficiaries.build(beneficiary_subcategory: beneficiary) if beneficiary
      end
    end    
    
  end
end
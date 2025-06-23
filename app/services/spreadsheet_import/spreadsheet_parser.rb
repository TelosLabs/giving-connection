module SpreadsheetImport
  class SpreadsheetParser
    ASSOCIATION_NAMES = ["orgs", "presets"].freeze

    def initialize(spreadsheet:, creator:, import_log: nil)
      @spreadsheet = spreadsheet
      @creator = creator
      @import_log = import_log
      @file_path = File.open(Rails.root.join("db/uploads").to_s)
      @csv_file_paths = csv_file_paths
    end

    def call
      # load_presets
      import
    end

    private

    def csv_file_paths
      data_spreadsheet = Roo::Spreadsheet.open(@spreadsheet)

      missing_sheets = ASSOCIATION_NAMES - data_spreadsheet.sheets.map(&:to_s)
      if missing_sheets.any?
        raise "Missing required sheets: #{missing_sheets.join(", ")}"
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
      @error_messages_by_row = Hash.new { |hash, key| hash[key] = [] }
      organizations = create_models

      organizations.each do |entry|
        row_number = entry[:row_number]
        org = entry[:org]
        entry[:org_row]

        org_import_result = Organization.import([org], recursive: true, track_validation_failures: true)

        if org_import_result&.ids&.any?
          org.run_callbacks(:create) { true }
          Rails.logger.warn "Import SUCCESSFUL for organization at row #{row_number} (name: #{org.name})"
        else
          Rails.logger.warn "Import failed for organization at row #{row_number} (name: #{org.name})"
        end
      end

      formatted_errors = @error_messages_by_row.map do |label, messages|
        ["#{label}:", *messages.map { |msg| "• #{msg}" }].join("\n")
      end.join("\n\n")

      @import_log.update!(
        error_messages: formatted_errors.presence || "No errors found.",
        status: "completed"
      )
    end

    def create_models
      organizations = []
      CSV.foreach(@csv_file_paths[:orgs_csv_file], headers: :first_row).with_index(2) do |org_row, row_number|
        @import_log&.increment!(:total_rows)

        org_name = org_row["Organization Name"]
        if organization_already_exists?(org_name)
          Rails.logger.info "Skipping existing organization: #{org_name} (row #{row_number})"
          @import_log&.increment!(:skipped_count)
          next
        end

        new_organization = Organization.new(build_organization_hash(org_row))
        new_organization.creator = @creator
        new_organization.build_social_media(build_social_media_hash(org_row))
        build_location_from_org_row(new_organization, org_row)

        build_org_associations(new_organization, org_row)

        has_errors = log_organization_errors(row_number, org_row, new_organization)
        if has_errors
          Rails.logger.warn "❌ Skipping row #{row_number} due to missing data (#{org_name || "Unnamed Org"})"
          @import_log&.increment!(:error_count)
          next
        else
          @import_log&.increment!(:success_count)
        end

        organizations << {row_number: row_number, org: new_organization, org_row: org_row}
        Rails.logger.info "Prepared organization: #{new_organization.name} (row #{row_number})"
      rescue
        organizations << {row_number: row_number, org: new_organization, org_row: org_row}
        @import_log&.increment!(:error_count)
      end
      organizations
    end

    def organization_already_exists?(org_name)
      Organization.unscoped.exists?(name: org_name)
    end

    def build_organization_hash(org_row)
      {
        name: clean_na(org_row["Organization Name"]),
        ein_number: clean_na(org_row["EIN Number"]),
        irs_ntee_code: full_ntee_code(clean_na(org_row["IRS NTEE Code"])),
        mission_statement_en: clean_na(org_row["Mission Statement - What We Do"]),
        vision_statement_en: clean_na(org_row["Vision - Goals and Aspirations"]),
        tagline_en: clean_na(org_row["Services - How We Do It"]),
        mission_statement_es: nil,
        vision_statement_es: nil,
        tagline_es: nil,
        website: clean_na(org_row["Website link"]),
        donation_link: clean_na(org_row["Donation link"]),
        scope_of_work: clean_na(org_row["Scope of Work"]),
        active: true
      }
    end

    def build_social_media_hash(org_row)
      {
        facebook: clean_na(org_row["Facebook"]),
        instagram: clean_na(org_row["Instagram"]),
        twitter: clean_na(org_row["Twitter/X"]),
        linkedin: clean_na(org_row["LinkedIn"]),
        youtube: clean_na(org_row["YouTube"]),
        blog: clean_na(org_row["Blog"])
      }
    end

    def safe_non_standard_office_hours(value)
      valid_values = Location.non_standard_office_hours.keys

      cleaned = value.to_s.strip.downcase
      return cleaned if valid_values.include?(cleaned)

      nil
    end

    def build_location_from_org_row(organization, org_row)
      if org_row["Website link"].to_s.strip.downcase == "not found"
        Rails.logger.warn "⏭ Skipping location for #{organization.name} — organization marked as 'Not Found'"
        return "NA"
      end

      address = org_row["Address"]
      geo_result = nil
      timezone = nil

      begin
        geo_result = SpreadsheetImport::AddressLocationParser.new(address).call
      rescue => e
        Rails.logger.error "🌍 Failed to geocode address '#{address}': #{e.message}"
        return "geocode"
      end

      begin
        timezone = nil
        if geo_result
          timezone = SpreadsheetImport::TimezoneDetection.new(geo_result.latitude, geo_result.longitude).call
        else
          Rails.logger.warn "🌐 Skipping timezone detection — no geo result available."
          return "timezone"
        end
      rescue => e
        Rails.logger.error "🕒 Failed to detect timezone for '#{address}': #{e.message}"
        return "timezone"
      end

      location = organization.locations.build(
        name: clean_na(org_row["Organization Name"]),
        address: org_row["Address"],
        email: clean_na(org_row["Email"]),
        time_zone: timezone,
        offer_services: true,
        non_standard_office_hours: safe_non_standard_office_hours(org_row["Hours of Operation"]),
        youtube_video_link: clean_na(org_row["YouTube Video Link"]),
        website: clean_na(org_row["Website link"]),
        latitude: geo_result&.latitude,
        longitude: geo_result&.longitude,
        main: true
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
        SpreadsheetImport::OfficeHoursParser.new(hours_string).call.each do |attrs|
          location.office_hours.build(attrs)
        end
      end
      true
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

    def full_ntee_code(raw_code)
      return nil if raw_code.blank?

      normalized_code = raw_code.strip.upcase
      Organizations::Constants::NTEE_CODE.find { |entry| entry.start_with?(normalized_code) }
    end

    def log_organization_errors(row_number, org_row, organization, exception = nil)
      org_name = org_row["Organization Name"]
      label = "Row #{row_number} — #{org_name.presence || "Unnamed Org"}"
      had_errors = false

      if exception
        Rails.logger.error "#{label}: #{exception.message}"
        @error_messages_by_row[label] << exception.message
        had_errors = true
      end

      if clean_na(organization&.mission_statement_en).blank?
        @error_messages_by_row[label] << "Missing mission statement"
        had_errors = true
      end

      if clean_na(organization&.locations).blank?
        @error_messages_by_row[label] << "Missing location"
        had_errors = true
      else
        location = organization.locations.first

        if clean_na(location.address).blank?
          @error_messages_by_row[label] << "Missing address"
          had_errors = true
        end

        if clean_na(location.latitude).blank? || clean_na(location.longitude).blank?
          @error_messages_by_row[label] << "Missing geolocation data"
          had_errors = true
        end

        if clean_na(location.time_zone).blank?
          @error_messages_by_row[label] << "Missing time zone"
          had_errors = true
        end

        if clean_na(location.office_hours).blank? && clean_na(location.non_standard_office_hours).blank?
          @error_messages_by_row[label] << "Missing office hours"
          had_errors = true
        end
      end

      had_errors
    end

    def clean_na(value)
      return nil if value.blank?

      cleaned = value.to_s.strip
      return nil if ["NA", "N/A"].include?(cleaned.upcase)

      cleaned.gsub(/[#\/]+\z/, "")
    end
  end
end

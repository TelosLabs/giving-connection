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
      #load_presets
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
      total_import_results = { ids: [], failed_instances: [] }
      organizations = create_models

      organizations.each_with_index do |org, i|
        org_import_result = Organization.import([org], recursive: true, track_validation_failures: true)

        if org_import_result&.ids&.any?
          org.run_callbacks(:create) { true }
          total_import_results[:ids] << org_import_result.ids.first
          Rails.logger.warn "Import SUCCESSFUL for organization at row #{i + 2} (name: #{org.name})"
        else
          Rails.logger.warn "Import failed for organization at row #{i + 2} (name: #{org.name})"
          if org_import_result
            org_import_result.failed_instances.each do |row_index, failed_org|
              total_import_results[:failed_instances] << { row: row_index, org: failed_org }
            end
          end
        end
      end
      total_import_results
    end


    def create_models
      organizations = []
      CSV.foreach(@csv_file_paths[:orgs_csv_file], headers: :first_row).with_index(2) do |org_row, row_number|
        begin
          @import_log&.increment!(:total_rows)

          org_name = org_row["Organization Name"]
          if organization_already_exists?(org_name)
            Rails.logger.info "Skipping existing organization: #{org_name} (row #{row_number})"
            @import_log&.increment!(:success_count)
            next
          end

          new_organization = Organization.new(build_organization_hash(org_row))
          new_organization.creator = @creator
          new_organization.build_social_media(build_social_media_hash(org_row))
          location_success = build_location_from_org_row(new_organization, org_row)
          if location_success != true
            Rails.logger.warn "⏭ Skipping organization #{org_name} at row #{row_number} due to incomplete info"
            @import_log&.increment!(:skipped_count)
            case location_success
            when "NA"
              Rails.logger.warn "⏭ Skipping organization #{org_name} at row #{row_number} due to incomplete info"
              @import_log&.increment!(:skipped_count)
            when "geocode"
              Rails.logger.warn "⏭ Error in organization #{org_name} at row #{row_number} due to address issue"
              @import_log&.increment!(:error_count)
            when "timezone"
              Rails.logger.warn "⏭ Error in organization #{org_name} at row #{row_number} due to timezone issue"
              @import_log&.increment!(:error_count)
            end
            next
          end
          build_org_associations(new_organization, org_row)

          organizations << new_organization
          Rails.logger.info "Prepared organization: #{new_organization.name} (row #{row_number})"
          @import_log&.increment!(:success_count)
        rescue => e
          Rails.logger.error "Error building organization at row #{row_number}: #{e.message}"
          @import_log&.increment!(:error_count)
        ensure
          row_number += 1
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
        irs_ntee_code: full_ntee_code(org_row["IRS NTEE Code"]),
        mission_statement_en: org_row["Mission Statement - What We Do"],
        vision_statement_en: org_row["Vision - Goals and Aspirations"],
        tagline_en: org_row["Services - How We Do It"],
        mission_statement_es: nil,
        vision_statement_es: nil,
        tagline_es: nil,
        website: org_row["Website link"],
        donation_link: org_row["Donation link"],
        scope_of_work: org_row["Scope of Work"],
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
        name: "Main Location",
        address: org_row["Address"],
        email: org_row["Email"],
        time_zone: timezone,
        offer_services: true,
        non_standard_office_hours: safe_non_standard_office_hours(org_row["Hours of Operation"]),
        youtube_video_link: org_row["YouTube Video Link"],
        website: org_row["Website link"],
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
    
  end
end
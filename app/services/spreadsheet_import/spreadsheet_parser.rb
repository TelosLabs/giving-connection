require "tmpdir"

module SpreadsheetImport
  class SpreadsheetParser
    # Only the "orgs" sheet is consumed. Preset lookups (causes/services/
    # beneficiaries) are matched against records that already exist in the DB.
    ASSOCIATION_NAMES = ["orgs"].freeze

    def initialize(spreadsheet:, creator:, import_log: nil)
      @spreadsheet = spreadsheet
      @creator = creator
      @import_log = import_log
      # Each import gets its own scratch directory so concurrent imports can't
      # clobber each other's intermediate CSV files.
      @work_dir = Dir.mktmpdir("spreadsheet_import")
      @csv_file_paths = csv_file_paths
      @imported_names = Set.new
    end

    def call
      import
    ensure
      cleanup_work_dir
    end

    private

    def csv_file_paths
      data_spreadsheet = Roo::Spreadsheet.open(@spreadsheet)

      missing_sheets = ASSOCIATION_NAMES - data_spreadsheet.sheets.map(&:to_s)
      if missing_sheets.any?
        raise "Missing required sheets: #{missing_sheets.join(", ")}"
      end

      ASSOCIATION_NAMES.each do |sheet_name|
        data_spreadsheet.default_sheet = sheet_name
        data_spreadsheet.to_csv("#{@work_dir}/#{sheet_name}.csv")
      end

      ASSOCIATION_NAMES.each_with_object({}) do |file_name, hash|
        hash[:"#{file_name}_csv_file"] = "#{@work_dir}/#{file_name}.csv"
      end
    end

    def cleanup_work_dir
      FileUtils.remove_entry(@work_dir) if @work_dir && Dir.exist?(@work_dir)
    rescue => e
      Rails.logger.warn "Failed to clean up import work dir: #{e.message}"
    end

    def import
      @error_messages_by_row = Hash.new { |hash, key| hash[key] = [] }
      organizations = create_models

      organizations.each do |entry|
        row_number = entry[:row_number]
        org = entry[:org]
        next if org.nil?

        label = row_label(row_number, entry[:org_row])

        org_import_result =
          Organization.import([org],
            recursive: true,
            validate: true,
            track_validation_failures: true)

        failed =
          if org_import_result.respond_to?(:failed_instances_with_indexes)
            org_import_result.failed_instances_with_indexes
          else
            org_import_result.failed_instances
          end

        if failed.present?
          @import_log&.increment!(:error_count)
          Rails.logger.warn "Import FAILED for organization at row #{row_number} (name: #{org.name})"

          Array(failed).each do |item|
            idx, inst = item.is_a?(Array) ? item : [nil, item]
            if inst.respond_to?(:errors) && inst.errors.any?
              inst.errors.full_messages.each { |msg| @error_messages_by_row[label] << msg }
            else
              @error_messages_by_row[label] << "Database/association error on #{inst.class.name}#{idx ? " (index #{idx})" : ""}"
            end
          end
        else
          @import_log&.increment!(:success_count)
          attach_media(org_import_result.ids, entry[:org_row])
          @imported_names.add(org.name) if org.name.present?
          Rails.logger.info "Import SUCCESSFUL for organization at row #{row_number} (name: #{org.name})"
        end
      end

      finalize_import_log
    end

    # activerecord-import skips ActiveRecord callbacks, so the default
    # logo/cover the after_create hook would normally attach never gets set.
    # Without them, views that render the org's logo (map pins, info windows,
    # detail pages) raise and show "Content missing".
    #
    # First try to attach the real logo from the spreadsheet's "Logo" URL, then
    # fall back to the bundled defaults for whatever is still missing (cover
    # always defaults; logo defaults only when the download failed or was blank).
    def attach_media(org_ids, org_row)
      logo_url = org_row && org_row["Logo"]

      Organization.where(id: org_ids).find_each do |org|
        attach_remote_logo(org, logo_url)
        org.ensure_default_media!
      end
    rescue => e
      Rails.logger.warn "Failed to attach logo/cover for #{org_ids.inspect}: #{e.message}"
    end

    def attach_remote_logo(org, logo_url)
      payload = SpreadsheetImport::LogoDownloader.new(logo_url).call
      return if payload.nil?

      org.logo.attach(
        io: payload[:io],
        filename: payload[:filename],
        content_type: payload[:content_type]
      )
      Rails.logger.info "🖼 Attached remote logo for #{org.name}"
    rescue => e
      Rails.logger.warn "Failed to attach remote logo for #{org.name}: #{e.message}"
    end

    def finalize_import_log
      return unless @import_log

      formatted_errors = @error_messages_by_row.map do |row_label, messages|
        ["#{row_label}:", *messages.map { |msg| "• #{msg}" }].join("\n")
      end.join("\n\n")

      @import_log.reload
      status =
        if @import_log.success_count.zero? && @import_log.error_count.positive?
          "failed"
        else
          "completed"
        end

      @import_log.update!(
        error_messages: formatted_errors.presence || "No errors found.",
        status: status
      )
    end

    def create_models
      organizations = []
      CSV.foreach(@csv_file_paths[:orgs_csv_file], headers: :first_row).with_index(2) do |org_row, row_number|
        @import_log&.increment!(:total_rows)

        # Use the cleaned name for both the duplicate check and storage so the
        # two never disagree (which would defeat de-duplication).
        org_name = clean_na(org_row["Organization Name"])

        if org_name.present? && organization_already_exists?(org_name)
          Rails.logger.info "Skipping existing organization: #{org_name} (row #{row_number})"
          @import_log&.increment!(:skipped_count)
          next
        end

        if org_name.present? && @imported_names.include?(org_name)
          Rails.logger.warn "⚠️ Skipping duplicate organization in batch: #{org_name} (row #{row_number})"
          @import_log&.increment!(:skipped_count)
          next
        end

        new_organization = Organization.new(build_organization_hash(org_row))
        new_organization.creator = @creator
        new_organization.build_social_media(build_social_media_hash(org_row))
        # A location that can't be built (bad address, non-US time zone, etc.)
        # is a non-blocking note — the organization still imports without one.
        build_location_from_org_row(new_organization, org_row, row_number)
        build_org_associations(new_organization, org_row)

        has_errors = log_organization_errors(row_number, org_row, new_organization)

        if has_errors
          Rails.logger.warn "❌ Skipping row #{row_number} due to errors (#{org_name || "Unnamed Org"})"
          @import_log&.increment!(:error_count)
          next
        end

        @imported_names.add(org_name) if org_name.present?
        organizations << {row_number: row_number, org: new_organization, org_row: org_row}
        Rails.logger.info "Prepared organization: #{new_organization.name} (row #{row_number})"
      rescue => e
        @import_log&.increment!(:error_count)
        @error_messages_by_row[row_label(row_number, org_row)] << "Unexpected error: #{e.message}"
        Rails.logger.error "Exception preparing row #{row_number}: #{e.message}"
        next
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
        mission_statement_en: clean_na(org_row["Mission Statement - What We Do"]) || "Visit organization's website for more details",
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

    def normalize_non_standard_office_hours(value)
      valid = Location.non_standard_office_hours.keys
      v = clean_na(value)&.downcase
      return nil if v.blank?
      return v if valid.include?(v)

      return "appointment_only" if v.include?("appointment")
      return "always_open" if v.include?("always open")

      nil
    end

    # A location is best-effort: if it can't be built the organization still
    # imports without one, and the reason is recorded as a non-blocking note so
    # it's visible in the log rather than silently dropped.
    #
    # Returns :ok when a location was attached, :skipped otherwise.
    def build_location_from_org_row(organization, org_row, row_number)
      label = row_label(row_number, org_row)

      if org_row["Website link"].to_s.strip.downcase == "not found"
        Rails.logger.warn "⏭ Skipping location for #{organization.name} — organization marked as 'Not Found'"
        return :skipped
      end

      address = org_row["Address"]
      if address.to_s.strip.blank?
        note_location_skipped(label, "no address provided")
        return :skipped
      end

      geo_result =
        begin
          SpreadsheetImport::AddressLocationParser.new(address).call
        rescue => e
          Rails.logger.error "🌍 Failed to geocode address '#{address}': #{e.message}"
          nil
        end

      if geo_result.nil?
        note_location_skipped(label, "could not geocode address '#{address}'")
        return :skipped
      end

      timezone =
        begin
          SpreadsheetImport::TimezoneDetection.new(geo_result.latitude, geo_result.longitude).call
        rescue => e
          Rails.logger.error "🕒 Failed to detect timezone for '#{address}': #{e.message}"
          nil
        end

      if timezone.blank?
        note_location_skipped(label, "could not determine time zone for address '#{address}'")
        return :skipped
      end

      unless supported_time_zone?(timezone)
        note_location_skipped(label, "unsupported (non-US) time zone '#{timezone}' for address '#{address}'")
        return :skipped
      end

      hours_string = org_row["Detailed Hours Of Operation"]
      office_hours =
        if hours_string.present?
          SpreadsheetImport::OfficeHoursParser.new(hours_string).call
        else
          []
        end

      # Only fall back to "no set business hours" when we have neither an
      # explicit non-standard designation nor parsed weekly hours. When real
      # hours are present we leave the flag blank so they are actually used.
      non_standard = normalize_non_standard_office_hours(org_row["Hours of Operation"])
      non_standard = "no_set_business_hours" if non_standard.blank? && office_hours.blank?

      location = organization.locations.build(
        name: clean_na(org_row["Organization Name"]),
        address: address,
        email: clean_na(org_row["Email"]),
        time_zone: timezone,
        offer_services: true,
        non_standard_office_hours: non_standard,
        youtube_video_link: clean_na(org_row["YouTube Video Link"]),
        website: clean_na(org_row["Website link"]),
        latitude: geo_result.latitude,
        longitude: geo_result.longitude,
        main: true
      )

      phone_number = org_row["Phone"]
      location.build_phone_number(number: phone_number, main: true) if phone_number.present?

      services = (org_row["Services"] || "").split(",").map(&:strip)
      services.each do |service_name|
        service = Service.find_by(name: service_name)
        location.location_services.build(service: service) if service
      end

      # activerecord-import (see #import) skips ActiveRecord save callbacks, so
      # OfficeHour's before_save :convert_times_to_utc never runs during a bulk
      # import. Without it the parser's wall-clock strings ("10:00") get stored
      # verbatim and then shifted by the timezone on display (e.g. a 10-15 range
      # shows as 3-8 for an Arizona location). Convert to UTC here so the imported
      # value matches what a normal save would have produced.
      office_hours.each do |attrs|
        office_hour = location.office_hours.build(attrs)
        office_hour.convert_times_to_utc
      end

      :ok
    end

    def supported_time_zone?(timezone)
      ActiveSupport::TimeZone.us_zones.map(&:name).include?(timezone)
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
      codes = Organizations::Constants::NTEE_CODE

      # Prefer an exact match, then a match on the "<code>:" prefix, and only
      # then a loose prefix match — otherwise a short code like "A2" could
      # silently bind to the first entry that merely starts with it.
      codes.find { |entry| entry == normalized_code } ||
        codes.find { |entry| entry.start_with?("#{normalized_code}:") } ||
        codes.find { |entry| entry.start_with?(normalized_code) }
    end

    def note_location_skipped(label, reason)
      Rails.logger.warn "📍 #{label}: imported without a location — #{reason}"
      @error_messages_by_row[label] << "Note: imported without a location — #{reason}"
    end

    def row_label(row_number, org_row)
      org_name = clean_na(org_row && org_row["Organization Name"])
      "Row #{row_number} — #{org_name.presence || "Unnamed Org"}"
    end

    def log_organization_errors(row_number, org_row, organization)
      label = row_label(row_number, org_row)
      had_errors = false

      if clean_na(organization&.mission_statement_en).blank?
        @error_messages_by_row[label] << "Missing mission statement"
        had_errors = true
      end

      had_errors
    end

    def clean_na(value)
      return nil if value.blank?

      cleaned = value.to_s.strip
      return nil if ["NA", "N/A"].include?(cleaned.upcase)

      cleaned = cleaned.gsub(/\Amailto:/i, "")

      cleaned.gsub(/[#\/]+\z/, "")
    end
  end
end

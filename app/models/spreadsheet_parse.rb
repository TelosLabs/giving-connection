class SpreadsheetParse
  ASSOCIATION_NAMES = ["orgs", "tags", "beneficiaries", "causes",
    "locations", "location_services", "location_office_hours", "location_phone_number"].freeze

  def import(spreadsheet)
    file_path = File.open(Rails.root.join("db/uploads").to_s)
    csv_file_paths = csv_file_paths(spreadsheet, file_path)
    organizations = create_models(csv_file_paths)
    results = import_organizations(organizations)
    execute_callbacks(results) if results.ids.any?
    results
  end

  def csv_file_paths(spreadsheet, file_path)
    ASSOCIATION_NAMES.each_with_object({}) do |file_name, hash|
      hash[:"#{file_name}_csv_file"] = "#{file_path.path}/#{file_name}.csv"
    end
  end

  def create_models(csv_file_paths, organizations = [])
    CSV.foreach(csv_file_paths[:orgs_csv_file], headers: :first_row) do |org_row|
      next if organization_already_exists?(org_row["name"])
      new_organization = Organization.new(build_organization_hash(org_row))

      next unless new_organization
      new_organization.build_social_media(build_social_media_hash(org_row))
      new_organization = create_organization_associated_records(csv_file_paths, new_organization, org_row["id"])
      organizations << new_organization
    end
    organizations
  end

  def organization_already_exists?(org_name)
    Organization.unscoped.exists?(name: org_name)
  end

  def create_organization_associated_records(csv_file_paths, new_organization, org_id)
    create_associated_records(csv_file_paths[:tags_csv_file], new_organization, "organization_id", :tags, Tag, org_id)
    create_associated_records(csv_file_paths[:beneficiaries_csv_file], new_organization, "organization_id", :organization_beneficiaries, BeneficiarySubcategory, org_id)
    create_associated_records(csv_file_paths[:causes_csv_file], new_organization, "organization_id", :organization_causes, Cause, org_id)

    create_locations_location_services_office_hours_and_phone_numbers(
      csv_file_paths[:locations_csv_file],
      csv_file_paths[:location_services_csv_file],
      csv_file_paths[:location_office_hours_csv_file],
      csv_file_paths[:location_phone_number_csv_file],
      new_organization, org_id
    )
    new_organization
  end

  def create_associated_records(csv_file_path, new_object, id_key, association_name, model_name, org_id)
    CSV.foreach(csv_file_path, headers: :first_row) do |row|
      if row[id_key] == org_id
        case association_name
        when :tags
          new_object.send(association_name).build(name: row["name"])
        when :organization_beneficiaries, :organization_causes
          data = model_name.find_by_name(row["name"])
          new_object.send(association_name).build("#{model_name.to_s.underscore}": data)
        end
      end
    end
  end

  def create_locations(csv_file_paths, new_organization, org_id)
  end

  def create_locations_location_services_office_hours_and_phone_numbers(locations_csv_file_path, location_services_csv_file_path, location_office_hours_csv_file, location_phone_number_csv_file, new_organization, org_id)
    CSV.foreach(locations_csv_file_path, headers: :first_row) do |location_row|
      if location_row["organization_id"] == org_id
        new_location = new_organization.locations.build(build_location_hash(location_row))
        create_location_services(location_services_csv_file_path, new_location, location_row["id"])
        create_location_office_hours(location_office_hours_csv_file, new_location, location_row["id"]) unless CSV.read(location_office_hours_csv_file).length < 1
        create_location_phone_number(location_phone_number_csv_file, new_location, location_row["id"])
      end
    end
  end

  def create_location_services(location_services_csv_file_path, new_location, location_id)
    CSV.foreach(location_services_csv_file_path, headers: :first_row) do |location_service_row|
      if location_service_row["location_id"] == location_id
        service = Service.find_by_name(location_service_row["name"])
        new_location.location_services.build(service: service)
      end
    end
  end

  def create_location_office_hours(office_hours_file_path, new_location, location_id)
    CSV.foreach(office_hours_file_path, headers: :first_row) do |office_hour_row|
      day = office_hour_row["day"]
      open_time = office_hour_row["open_time"]
      close_time = office_hour_row["close_time"]
      closed = office_hour_row["closed"] == "yes"

      if office_hour_row["location_id"] == location_id && day.present?
        new_location.office_hours.build(
          day: Date::DAYNAMES.index(day),
          open_time: open_time,
          close_time: close_time,
          closed: closed
        )
      end
    end
  end

  def create_location_phone_number(location_phone_number_csv_file, new_location, location_id)
    CSV.foreach(location_phone_number_csv_file, headers: :first_row) do |location_phone_number_row|
      phone_number = location_phone_number_row["number"]
      if location_phone_number_row["location_id"] == location_id && phone_number.present?
        main = location_phone_number_row["main"] == "yes"
        new_location.build_phone_number(number: phone_number, main: main)
      end
    end
  end

  def build_organization_hash(org_row)
    {name: org_row["name"], ein_number: org_row["ein_number"], irs_ntee_code: org_row["irs_ntee_code"],
     mission_statement_en: org_row["mission_statement_en"], vision_statement_en: org_row["vision_statement_en"],
     tagline_en: org_row["tagline_en"], mission_statement_es: org_row["mission_statement_es"],
     vision_statement_es: org_row["vision_statement_es"], tagline_es: org_row["tagline_es"],
     website: org_row["website"], scope_of_work: org_row["scope_of_work"], creator: AdminUser.first,
     active: org_row["active"] == "yes",
     donation_link: org_row["donation_link"]}
  end

  def build_social_media_hash(org_row)
    {facebook: org_row["facebook"], instagram: org_row["instagram"],
     twitter: org_row["twitter"], linkedin: org_row["linkedin"], youtube: org_row["youtube"],
     blog: org_row["blog"]}
  end

  def build_location_hash(location_row)
    {address: location_row["address"], website: location_row["website"],
     main: location_row["main"] == "yes",
     non_standard_office_hours: location_row["non_standard_office_hours"].presence || nil,
     offer_services: location_row["offer_services"] == "yes",
     name: location_row["name"],
     latitude: location_row["latitude"].present? ? location_row["latitude"].to_f : nil,
     longitude: location_row["longitude"].present? ? location_row["longitude"].to_f : nil,
     time_zone: location_row["time_zone"].presence,
     email: location_row["email"], youtube_video_link: location_row["youtube_video_link"]}
  end

  def import_organizations(organizations = [])
    Organization.import(
      organizations,
      recursive: true,
      track_validation_failures: true
    )
  end

  def execute_callbacks(results)
    results.ids.each do |org_id|
      org = Organization.find(org_id)
      org.run_callbacks(:create) { true }
    end
  end
end

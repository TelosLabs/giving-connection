# frozen_string_literal: true

class SpreadsheetParse
  FILES_NAME = ['orgs.csv', 'tags.csv', 'beneficiaries.csv', 'causes.csv',
                'locations.csv', 'location_services.csv', 'location_office_hours.csv', 'location_phone_number.csv'].freeze

  def import(spreadsheet)
    file_path = File.open(File.join(Rails.root, 'db', 'uploads'))
    csv_file_paths = spreadsheet_to_csv(spreadsheet, file_path)
    create_models(csv_file_paths)
  end

  def spreadsheet_to_csv(spreadsheet, file_path)
    data_spreadsheet = Roo::Spreadsheet.open(spreadsheet)

    FILES_NAME.each_with_index do |file_name, sheet|
      data_spreadsheet.default_sheet = data_spreadsheet.sheets[sheet]
      data_spreadsheet.to_csv("#{file_path.path}/#{file_name}")
    end

    paths =
      { orgs_csv_file: "#{file_path.path}/orgs.csv",
        tags_csv_file: "#{file_path.path}/tags.csv",
        beneficiaries_csv_file: "#{file_path.path}/beneficiaries.csv",
        causes_csv_file: "#{file_path.path}/causes.csv",
        locations_csv_file: "#{file_path.path}/locations.csv",
        location_services_csv_file: "#{file_path.path}/location_services.csv",
        location_office_hours_csv_file: "#{file_path.path}/location_office_hours.csv",
        location_phone_number_csv_file: "#{file_path.path}/location_phone_number.csv" }
  end

  def create_models(csv_file_paths)
    CSV.foreach(csv_file_paths[:orgs_csv_file], headers: :first_row) do |org_row|
      next if organization_already_exists?(org_row['name'])

      new_organization = Organization.new(build_organization_hash(org_row))
      next unless new_organization

      new_organization.build_social_media(build_social_media_hash(org_row))
      create_tags(csv_file_paths[:tags_csv_file], new_organization, org_row['id'])
      create_organization_beneficiaries(csv_file_paths[:beneficiaries_csv_file], new_organization, org_row['id'])
      create_organization_causes(csv_file_paths[:causes_csv_file], new_organization, org_row['id'])
      create_locations_location_services_office_hours_and_phone_numbers(
        csv_file_paths[:locations_csv_file],
        csv_file_paths[:location_services_csv_file],
        csv_file_paths[:location_office_hours_csv_file],
        csv_file_paths[:location_phone_number_csv_file],
        new_organization, org_row['id']
      )

      new_organization.save
    end
  end

  def organization_already_exists?(org_name)
    Organization.unscoped.exists?(name: org_name)
  end

  def create_tags(tags_csv_file_path, new_organization, org_id)
    CSV.foreach(tags_csv_file_path, headers: :first_row) do |tag_row|
      new_organization.tags.build(name: tag_row['name']) if tag_row['organization_id'] == org_id
    end
  end

  def create_organization_beneficiaries(beneficiaries_csv_file_path, new_organization, org_id)
    CSV.foreach(beneficiaries_csv_file_path, headers: :first_row) do |beneficiary_row|
      if beneficiary_row['organization_id'] == org_id
        beneficiary_subcategory = BeneficiarySubcategory.find_by_name(beneficiary_row['name'])
        new_organization.organization_beneficiaries.build(beneficiary_subcategory: beneficiary_subcategory) if beneficiary_subcategory.present?
      end
    end
  end

  def create_organization_causes(causes_csv_file_path, new_organization, org_id)
    CSV.foreach(causes_csv_file_path, headers: :first_row) do |cause_row|
      if cause_row['organization_id'] == org_id
        cause = Cause.find_by_name(cause_row['name'])
        new_organization.organization_causes.build(cause: cause) if cause.present?
      end
    end
  end

  def create_locations_location_services_office_hours_and_phone_numbers(locations_csv_file_path, location_services_csv_file_path, location_office_hours_csv_file, location_phone_number_csv_file, new_organization, org_id)
    CSV.foreach(locations_csv_file_path, headers: :first_row) do |location_row|
      if location_row['organization_id'] == org_id
        new_location = new_organization.locations.build(build_location_hash(location_row))
        create_location_services(location_services_csv_file_path, new_location, location_row['id'])
        create_location_office_hours(location_office_hours_csv_file, new_location, location_row['id']) unless CSV.read(location_office_hours_csv_file).length < 1
        create_location_phone_number(location_phone_number_csv_file, new_location, location_row['id'])
      end
    end
  end

  def create_location_services(location_services_csv_file_path, new_location, location_id)
    CSV.foreach(location_services_csv_file_path, headers: :first_row) do |location_service_row|
      if location_service_row['location_id'] == location_id
        service = Service.find_by_name(location_service_row['name'])
        new_location.location_services.build(service: service) if service.present?
      end
    end
  end

  def create_location_office_hours(office_hours_file_path, new_location, location_id)
    CSV.foreach(office_hours_file_path, headers: :first_row) do |office_hour_row|
      day = office_hour_row['day']
      open_time = office_hour_row['open_time']
      close_time = office_hour_row['close_time']
      closed = office_hour_row['closed'] == 'yes'

      if office_hour_row['location_id'] == location_id && day.present? && open_time && close_time.present?
        new_location.office_hours.build(
          day: Date::DAYNAMES.index(day),
          open_time: Time.now.change({ hour: open_time }).in_time_zone('Eastern Time (US & Canada)'),
          close_time: Time.now.change({ hour: close_time }).in_time_zone('Eastern Time (US & Canada)'),
          closed: closed
        )
      end
    end
  end

  def create_location_phone_number(location_phone_number_csv_file, new_location, location_id)
    CSV.foreach(location_phone_number_csv_file, headers: :first_row) do |location_phone_number_row|
      phone_number = location_phone_number_row['number']
      if location_phone_number_row['location_id'] == location_id && phone_number.present?
        main = location_phone_number_row['main'] == 'yes'
        new_location.build_phone_number(number: phone_number, main: main)
      end
    end
  end

  def build_organization_hash(org_row)
    { name: org_row['name'], ein_number: org_row['ein_number'], irs_ntee_code: org_row['irs_ntee_code'],
      mission_statement_en: org_row['mission_statement_en'], vision_statement_en: org_row['vision_statement_en'],
      tagline_en: org_row['tagline_en'], mission_statement_es: org_row['mission_statement_es'],
      vision_statement_es: org_row['vision_statement_es'], tagline_es: org_row['tagline_es'],
      website: org_row['website'], scope_of_work: org_row['scope_of_work'], creator: AdminUser.first, active: true }
  end

  def build_social_media_hash(org_row)
    { facebook: org_row['facebook'], instagram: org_row['instagram'],
      twitter: org_row['twitter'], linkedin: org_row['linkedin'], youtube: org_row['youtube'],
      blog: org_row['blog'] }
  end

  def build_location_hash(location_row)
    { address: location_row['address'], website: location_row['website'],
      main: location_row['main'] == 'yes', physical: location_row['physical'] == 'yes',
      appointment_only: location_row['appointment_only'] == 'yes',
      offer_services: location_row['offer_services'] == 'yes',
      name: location_row['name'],
      latitude: location_row['latitude'].present? ? location_row['latitude'].to_f : nil,
      longitude: location_row['longitude'].present? ? location_row['longitude'].to_f : nil,
      email: location_row['email'] }
  end
end

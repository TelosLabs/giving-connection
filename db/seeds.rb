# frozen_string_literal: true

# Admin Users
AdminUser.create!(email: 'admin@example.com', password: 'testing', password_confirmation: 'testing')

# Users
User.create!(email: 'user@example.com', password: 'testing', password_confirmation: 'testing')

# Orgs
org = Organization.new(
  name: 'Centerstone Clarksville',
  ein_number: rand(0..1000),
  irs_ntee_code: %w[A00 A90 A26 A91 A02 Q21].sample,
  website: 'centerstone@example.com',
  scope_of_work: %w[International National Regional].sample,
  mission_statement_en: Faker::Company.catch_phrase,
  vision_statement_en: Faker::Company.catch_phrase,
  tagline_en: Faker::Company.catch_phrase,
  description_en: Faker::Company.catch_phrase
)
org.creator = AdminUser.last

org.locations.build(
  lonlat: Geo.point(-87.3499228477923, 36.53588038686436),
  longitude: '-87.3499228477923',
  latitude: '36.53588038686436',
  address: 'Centerstone, 8th Street, Clarksville, TN, USA',
  main: true,
  offer_services: true,
  physical: true,
)

Date::DAYNAMES.each_with_index do |day, index|
  org.locations.first.office_hours.build(
    day: index,
    open_time: Time.now.change({ hour: "9:00" }),
    close_time: Time.now.change({ hour: "16:00" }),
    closed: ["Saturday", "Sunday"].include?(day)
  )
end

puts "Org with id #{org.id} sucessfully created" if org.save!

org = Organization.new(
  name: 'NAMI Tennessee',
  ein_number: rand(0..1000),
  irs_ntee_code: %w[A00 A90 A26 A91 A02 Q21].sample,
  website: 'nami@example.com',
  scope_of_work: %w[International National Regional].sample,
  mission_statement_en: Faker::Company.catch_phrase,
  vision_statement_en: Faker::Company.catch_phrase,
  tagline_en: Faker::Company.catch_phrase,
  description_en: Faker::Company.catch_phrase
)
org.creator = AdminUser.last

org.locations.build(
  lonlat: Geo.point(-86.70336982081703, 36.12308987261626),
  longitude: '-86.70336982081703',
  latitude: '36.12308987261626',
  address: 'NAMI Tennessee, Kermit Drive, Nashville, Tennessee, USA',
  main: true,
  offer_services: true,
  physical: true,
)

Date::DAYNAMES.each_with_index do |day, index|
  org.locations.first.office_hours.build(
    day: index,
    open_time: Time.now.change({ hour: "9:00" }),
    close_time: Time.now.change({ hour: "16:00" }),
    closed: false
  )
end

puts "Org with id #{org.id} sucessfully created" if org.save!

org = Organization.new(
  name: 'Mental Health America of the MidSouth',
  ein_number: rand(0..1000),
  irs_ntee_code: %w[A00 A90 A26 A91 A02 Q21].sample,
  website: 'mental@example.com',
  scope_of_work: %w[International National Regional].sample,
  mission_statement_en: Faker::Company.catch_phrase,
  vision_statement_en: Faker::Company.catch_phrase,
  tagline_en: Faker::Company.catch_phrase,
  description_en: Faker::Company.catch_phrase
)
org.creator = AdminUser.last

org.locations.build(
  lonlat: Geo.point(-86.69885745944305, 36.08984574780193),
  longitude: '-86.69885745944305',
  latitude: '36.08984574780193',
  address: 'Mental Health America of the MidSouth, Nashville, TN, USA',
  main: true,
  offer_services: true,
  physical: true,
)

Date::DAYNAMES.each_with_index do |day, index|
  org.locations.first.office_hours.build(
    day: index,
    open_time: Time.now.change({ hour: "9:00" }),
    close_time: Time.now.change({ hour: "16:00" }),
    closed: false
  )
end

puts "Org with id #{org.id} sucessfully created" if org.save!

org = Organization.new(
  name: 'System of Care Across Tennessee',
  ein_number: rand(0..1000),
  irs_ntee_code: %w[A00 A90 A26 A91 A02 Q21].sample,
  website: 'systemofcare@example.com',
  scope_of_work: %w[International National Regional].sample,
  mission_statement_en: Faker::Company.catch_phrase,
  vision_statement_en: Faker::Company.catch_phrase,
  tagline_en: Faker::Company.catch_phrase,
  description_en: Faker::Company.catch_phrase
)
org.creator = AdminUser.last

org.locations.build(
  lonlat: Geo.point(-86.78218038642588, 36.16560224965609),
  longitude: '-86.78218038642588',
  latitude: '36.16560224965609',
  address: 'System of Care Across Tennessee',
  main: true,
  offer_services: true,
  physical: true,
)

Date::DAYNAMES.each_with_index do |day, index|
  org.locations.first.office_hours.build(
    day: index,
    open_time: Time.now.change({ hour: "9:00" }),
    close_time: Time.now.change({ hour: "16:00" }),
    closed: ["Saturday", "Sunday"].include?(day)
  )
end

puts "Org with id #{org.id} sucessfully created" if org.save!


# Beneficiaries
Organizations::Constants::BENEFICIARIES.each do |beneficiary, subbeneficiaries|
  new_beneficiary = BeneficiaryGroup.new(name: beneficiary)

  puts "#{new_beneficiary.name} sucessfully created" if new_beneficiary.save!

  subbeneficiaries.each do |subbeneficiary|
    new_subbeneficiary = BeneficiarySubcategory.new(name: subbeneficiary, beneficiary_group: new_beneficiary)

    puts "#{new_subbeneficiary.name} sucessfully created" if new_subbeneficiary.save!
  end
end


# Causes and Services
Organizations::Constants::CAUSES_AND_SERVICES.each do |cause, services|
  new_cause = Cause.new(name: cause)

  puts "#{new_cause.name} sucessfully created" if new_cause.save!

  services.each do |service|
    new_service = Service.new(name: service, cause: new_cause)

    puts "#{new_service.name} sucessfully created" if new_service.save!
  end
end

file_path = File.open(File.join(Rails.root, 'db', 'uploads'))

data_spreadsheet = Roo::Spreadsheet.open("#{file_path.path}/Create-Organization-Template.xlsx")

data_spreadsheet.default_sheet = data_spreadsheet.sheets[0]
data_spreadsheet.to_csv("#{file_path.path}/orgs.csv")
orgs_csv_file = "#{file_path.path}/orgs.csv"

data_spreadsheet.default_sheet = data_spreadsheet.sheets[1]
data_spreadsheet.to_csv("#{file_path.path}/tags.csv")
tags_csv_file = "#{file_path.path}/tags.csv"

data_spreadsheet.default_sheet = data_spreadsheet.sheets[2]
data_spreadsheet.to_csv("#{file_path.path}/beneficiaries.csv")
beneficiaries_csv_file = "#{file_path.path}/beneficiaries.csv"

data_spreadsheet.default_sheet = data_spreadsheet.sheets[3]
data_spreadsheet.to_csv("#{file_path.path}/locations.csv")
locations_csv_file = "#{file_path.path}/locations.csv"

data_spreadsheet.default_sheet = data_spreadsheet.sheets[4]
data_spreadsheet.to_csv("#{file_path.path}/location_services.csv")
location_services_csv_file = "#{file_path.path}/location_services.csv"

data_spreadsheet.default_sheet = data_spreadsheet.sheets[5]
data_spreadsheet.to_csv("#{file_path.path}/location_office_hours.csv")
location_office_hours_csv_file = "#{file_path.path}/location_office_hours.csv"



CSV.foreach(orgs_csv_file, headers: :first_row) do |org_row|
  new_organization_data =  { name: org_row['name'], ein_number: org_row['ein_number'], irs_ntee_code: org_row['irs_ntee_code'],
      mission_statement_en: org_row['mission_statement_en'], vision_statement_en: org_row['vision_statement_en'],
      tagline_en: org_row['tagline_en'], description_en: org_row['description_en'],
      mission_statement_es: org_row['mission_statement_es'], vision_statement_es: org_row['vision_statement_es'],
      tagline_es: org_row['tagline_es'], description_es: org_row['description_es'], website: org_row['website'],
      scope_of_work: org_row['scope_of_work'], creator: AdminUser.first }

  new_organization = Organization.create!(new_organization_data)
  p new_organization

  social_media_data = { facebook: org_row['facebook'], instagram: org_row['instagram'], twitter: org_row['twitter'],
      linkedin: org_row['linkedin'], youtube: org_row['youtube'], blog: org_row['blog'], organization: new_organization }

  new_social_media = SocialMedia.create!(social_media_data)
  p new_social_media

  CSV.foreach(tags_csv_file, headers: :first_row) do |tag_row|
    if tag_row['organization_id'] == org_row['id']
      new_tag = Tag.create!(name: tag_row['name'], organization: new_organization)
      p new_tag
    end
  end
  
  CSV.foreach(beneficiaries_csv_file, headers: :first_row) do |beneficiary_row|
    if beneficiary_row['organization_id'] == org_row['id']
      beneficiary_subcategory = BeneficiarySubcategory.find_by_name(beneficiary_row['name'])
      new_organization_beneficiaries = 
        OrganizationBeneficiary.create!(beneficiary_subcategory: beneficiary_subcategory, organization: new_organization)
      p new_organization_beneficiaries
    end
  end

  CSV.foreach(locations_csv_file, headers: :first_row) do |location_row|
    if location_row['organization_id'] == org_row['id']
      new_location = Location.create!(address: location_row['address'], website: location_row['website'],
                                  main: location_row['main'] == 'yes', physical: location_row['physical'] == 'yes',
                                  appointment_only: location_row['appointment_only'] == 'yes',
                                  offer_services: location_row['offer_services'] == 'yes', organization: new_organization, 
                                  latitude: location_row['latitude'].to_f, longitude: location_row['longitude'].to_f)
      
      CSV.foreach(location_services_csv_file, headers: :first_row) do |location_service_row|
        if location_row['id'] == location_service_row['location_id']
          service = Service.find_by_name(location_service_row['name'])
          new_location_service = LocationService.create!(service: service, location: new_location)
          p new_location_service
        end
      end
    end
  end
end

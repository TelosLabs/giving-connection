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

Date::DAYNAMES.each do |day|
  org.locations.first.office_hours.build(
    day: day,
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

Date::DAYNAMES.each do |day|
  org.locations.first.office_hours.build(
    day: day,
    open_time: Time.now.change({ hour: "9:00" }),
    close_time: Time.now.change({ hour: "16:00" }),
    closed: ["Saturday", "Sunday"].include?(day)
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

Date::DAYNAMES.each do |day|
  org.locations.first.office_hours.build(
    day: day,
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

Date::DAYNAMES.each do |day|
  org.locations.first.office_hours.build(
    day: day,
    open_time: Time.now.change({ hour: "9:00" }),
    close_time: Time.now.change({ hour: "16:00" }),
    closed: ["Saturday", "Sunday"].include?(day)
  )
end

puts "Org with id #{org.id} sucessfully created" if org.save!

# Categories
Organizations::Constants::CATEGORIES.each do |category|
  new_category = Category.new(name: category)

  puts "#{new_category.name} sucessfully created" if new_category.save!
end

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
OrganizationConstants::CAUSES_AND_SERVICES.each do |cause, services|
  new_cause = Cause.new(name: cause)

  puts "#{new_cause.name} sucessfully created" if new_cause.save!

  services.each do |service|
    new_service = Service.new(name: service, cause: new_cause)

    puts "#{new_service.name} sucessfully created" if new_service.save!
  end
end

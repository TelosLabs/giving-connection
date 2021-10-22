# frozen_string_literal: true

# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Examples:
#
#   movies = Movie.create([{ name: 'Star Wars' }, { name: 'Lord of the Rings' }])
#   Character.create(name: 'Luke', movie: movies.first)

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
  physical: true
)
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
  physical: true
)
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
  physical: true
)

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
  physical: true
)

puts "Org with id #{org.id} sucessfully created" if org.save!

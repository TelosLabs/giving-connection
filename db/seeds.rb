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
3.times do
  org = Organization.new(
    name: Faker::Company.name,
    ein_number: rand(0..1000),
    irs_ntee_code: %w[A00 A90 A26 A91 A02 Q21].sample,
    website: 'org@email.com',
    scope_of_work: %w[International National Regional].sample,
    mission_statement_en: Faker::Company.catch_phrase,
    vision_statement_en: Faker::Company.catch_phrase,
    tagline_en: Faker::Company.catch_phrase,
    description_en: Faker::Company.catch_phrase
  )
  org.creator = AdminUser.last

  if org.save!
    puts "#{org.id} sucessfully created"
    SocialMedia.create!(organization: org)
  end

  puts "#{org.id} sucessfully created" if org.save!
end

# Services
# OrganizationConstants::SERVICES.each do |service|
#   new_service = Service.new(name: service)

#   if new_service.save!
#     puts "#{new_service.name} sucessfully created"
#   end
# end

# Categories
OrganizationConstants::CATEGORIES.each do |category|
  new_category = Category.new(name: category)

  puts "#{new_category.name} sucessfully created" if new_category.save!
end

# Beneficiaries
OrganizationConstants::BENEFICIARIES.each do |beneficiary, subbeneficiaries|
  new_beneficiary = Beneficiary.new(name: beneficiary)

  puts "#{new_beneficiary.name} sucessfully created" if new_beneficiary.save!

  subbeneficiaries.each do |subbeneficiary|
    new_subbeneficiary = BeneficiarySubcategory.new(name: subbeneficiary, beneficiary: new_beneficiary)

    puts "#{new_subbeneficiary.name} sucessfully created" if new_subbeneficiary.save!
  end
end

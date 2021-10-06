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

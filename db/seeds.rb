# frozen_string_literal: true

unless Rails.env.production?

  #Delete old records
  AdminUser.destroy_all
  Organization.destroy_all
  Service.destroy_all
  Cause.destroy_all
  BeneficiaryGroup.destroy_all
  Location.destroy_all
  Alert.destroy_all
  Message.destroy_all
  InstagramPost.destroy_all
  OfficeHour.destroy_all
  PhoneNumber.destroy_all
  SocialMedia.destroy_all
  Tag.destroy_all
  User.destroy_all

  # Admin Users
  AdminUser.create!(email: 'admin@example.com', password: 'testing', password_confirmation: 'testing')

  # Users
  User.create!(name: "test user", email: 'user@example.com', password: 'testing', password_confirmation: 'testing')

  # Causes and Services
  Rake::Task['populate:seed_causes_and_services'].invoke

  # Population served categories and subcategories
  Rake::Task['populate:seed_beneficiaries_and_beneficiaries_subcategories'].invoke

  # Parse xml
  SpreadsheetParse.new.import("./lib/assets/staging-data-19-01-2022.xlsx")

  # Create organizations and causes association
  Rake::Task['populate:seed_organizations_causes'].invoke

end
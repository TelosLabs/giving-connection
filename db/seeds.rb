# frozen_string_literal: true

unless Rails.env.production?

  # Delete old records
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

  # Admin users
  unless AdminUser.find_by(email: "admin@example.com")
    AdminUser.create!(
      email: "admin@example.com",
      password: "testing",
      password_confirmation: "testing"
    )
  end

  # Users
  unless User.find_by(email: "user@example.com")
    User.create!(
      name: "test user",
      email: "user@example.com",
      password: "testing",
      password_confirmation: "testing"
    )
  end

  # Causes and Services
  Rake::Task["populate:seed_causes_and_services"].invoke

  # Population served categories and subcategories
  Rake::Task["populate:seed_beneficiaries_and_beneficiaries_subcategories"].invoke

  # Populate organizations and locations
  SpreadsheetParse.new.import("./lib/assets/GC_Dummy_Data_for_DB.xlsx")

  # Phone Number
  PhoneNumber.find_or_create_by!(location: Location.first) do |phone|
    phone.number = "222-333-4444"
    main = false
  end
end

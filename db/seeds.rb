# frozen_string_literal: true

unless Rails.env.production? || Rails.env.test?

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
  User.destroy_all

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
  User.first.confirm

  # Causes and Services
  Rake::Task["populate:seed_causes_and_services"].invoke

  # Population served categories and subcategories
  Rake::Task["populate:seed_beneficiaries_and_beneficiaries_subcategories"].invoke

  # Populate organizations. The bulk-upload importer
  # (SpreadsheetImport::SpreadsheetParser) geocodes addresses and downloads
  # logos over the network, which isn't appropriate for seeding (slow, flaky,
  # and CI runs db:prepare before ImageMagick is even installed), so build a
  # handful of valid organizations directly instead. Locations are added below
  # by populate:random_locations, and the after_create hook attaches default
  # logo/cover art.
  admin = AdminUser.first
  5.times do |i|
    org = Organization.new(
      name: "#{Faker::Company.name} #{i}",
      ein_number: Faker::Number.number(digits: 9).to_s,
      irs_ntee_code: Organizations::Constants::NTEE_CODE.sample,
      scope_of_work: Organizations::Constants::SCOPE.sample,
      mission_statement_en: Faker::Company.catch_phrase,
      vision_statement_en: Faker::Company.bs,
      tagline_en: Faker::Company.buzzword,
      website: Faker::Internet.url,
      active: true
    )
    org.creator = admin
    org.organization_causes.build(cause: Cause.all.sample)
    org.save!
  end

  # Create Organization Admin
  OrganizationAdmin.find_or_create_by!(organization: Organization.first, user: User.first)

  # Create random locations around cities in US
  Rake::Task["populate:random_locations"].invoke

  # Phone Number — created after locations exist above.
  PhoneNumber.find_or_create_by!(location: Location.first) do |phone|
    phone.number = "222-333-4444"
    phone.main = false
  end

  # Create organizations and causes association
  Rake::Task["populate:seed_organizations_causes"].invoke
end

namespace :populate do
  desc "Seed causes and services to DB"
  task seed_causes_and_services: :environment do
    Organizations::Constants::CAUSES_AND_SERVICES.each do |cause, services|
      new_cause = Cause.create!(name: cause)
      services.each do |service|
        Service.create!(name: service, cause: new_cause)
      end
    end
  end

  desc "Seed beneficiaries groups and subcategories to DB"
  task seed_beneficiaries_and_beneficiaries_subcategories: :environment do
    Organizations::Constants::BENEFICIARIES.each do |beneficiary, subbeneficiaries|
      new_beneficiary = BeneficiaryGroup.create!(name: beneficiary)
      subbeneficiaries.each do |subbeneficiary|
        BeneficiarySubcategory.create!(name: subbeneficiary, beneficiary_group: new_beneficiary)
      end
    end
  end

  desc "Seed organizations and causes association"
  task seed_organizations_causes: :environment do
    Organization.all.find_each do |organization|
      OrganizationCause.create!(organization: organization, cause: Cause.all.sample)
      organization.update!(active: true)
    end
  end

  desc "Seed random Locations arround 1000 US cities"
  task random_locations: :environment do
    wb = Roo::Spreadsheet.open "./lib/assets/us_cities_coords.xlsx"
    sheet = wb.sheet(0)
    cities = sheet.parse(place_name: "place_name", latitude: "latitude", longitude: "longitude", clean: true)

    cities.each do |city|
      2.times do
        random_coords = RandomCoordinatesGenerator.call(central_lat: city[:latitude].to_f, central_lng: city[:longitude].to_f, max_radius: 1000)
        Location.create!(
          organization_id: Organization.all.sample.id,
          name: Faker::Company.name,
          address: city[:place_name],
          latitude: random_coords[:lat],
          longitude: random_coords[:lng],
          offer_services: false
        )
      end
    end
  end
end

namespace :populate do
  desc 'Seed causes and services to DB'
  task seed_causes_and_services: :environment do
    Organizations::Constants::CAUSES_AND_SERVICES.each do |cause, services|
      new_cause = Cause.create!(name: cause)
      services.each do |service|
        Service.create!(name: service, cause: new_cause)
      end
    end
  end

  desc 'Seed beneficiaries groups and subcategories to DB'
  task seed_beneficiaries_and_beneficiaries_subcategories: :environment do
    Organizations::Constants::BENEFICIARIES.each do |beneficiary, subbeneficiaries|
      new_beneficiary = BeneficiaryGroup.create!(name: beneficiary)
      subbeneficiaries.each do |subbeneficiary|
        BeneficiarySubcategory.create!(name: subbeneficiary, beneficiary_group: new_beneficiary)
      end
    end
  end

  desc 'Seed organizations and causes association'
  task seed_organizations_causes: :environment do
    Organization.all.each do |organization|
      OrganizationCause.create!(organization: organization, cause: Cause.all.sample)
      organization.update!(active: true)
    end
  end

  desc 'Locations cities arround US'
  task random_locations: :environment do
    def random_point_in_disk(max_radius)
      r = max_radius * (rand**0.5)
      theta = rand * 2 * Math::PI
      [r * Math.cos(theta), r * Math.sin(theta)]
    end

    wb = Roo::Spreadsheet.open "./lib/assets/us_cities_coords.xlsx"
    sheet = wb.sheet(0)
    cities_coords = sheet.parse(place_name: "place_name", latitude: "latitude", longitude:"longitude", clean:true)

    cities_coords.each do |city|
      2.times do
        lat = city[:latitude].to_f
        lng = city[:longitude].to_f
        max_radius = 1000 # mts
        earth_radius = 6371 # km
        one_degree = earth_radius * 2 * Math::PI / 360 * 1000 # 1° latitude in meters

        dx, dy = random_point_in_disk(max_radius)
        random_lat = lat + (dy / one_degree)
        random_lng = lng + (dx / (one_degree * Math::cos(lat * Math::PI / 180)))

        Location.create!(
          organization_id: Organization.first.id,
          name: 'Hanas corps',
          address: 'Anywhere within US',
          latitude: random_lat,
          longitude: random_lng,
          physical: true,
          offer_services: false
        )
      end
    end
  end
end

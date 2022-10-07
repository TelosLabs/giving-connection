namespace :populate do
  desc 'Seed causes and services to DB'
  task seed_causes_and_services: :environment do
    Organizations::Constants::CAUSES_AND_SERVICES.each do |cause, services|
      new_cause = Cause.create!(name: cause)
      print '.'
      services.each do |service|
        Service.create!(name: service, cause: new_cause)
        print '.'
      end
    end
    puts '.'
    puts 'Seeding causes and services finished!'
  end

  desc 'Seed beneficiaries groups and subcategories to DB'
  task seed_beneficiaries_and_beneficiaries_subcategories: :environment do
    Organizations::Constants::BENEFICIARIES.each do |beneficiary, subbeneficiaries|
      new_beneficiary = BeneficiaryGroup.create!(name: beneficiary)
      print '.'
      subbeneficiaries.each do |subbeneficiary|
        BeneficiarySubcategory.create!(name: subbeneficiary, beneficiary_group: new_beneficiary)
        print '.'
      end
    end
    puts '.'
    puts 'Seeding beneficiaries and beneficiaries subcategories finished!'
  end

  desc 'Seed organizations and causes association'
  task seed_organizations_causes: :environment do
    Organization.all.each do |org|
      OrganizationCause.create!(organization: org, cause: Cause.find(rand(1..16)))
      org.update!(active: true)
    end
  end
end

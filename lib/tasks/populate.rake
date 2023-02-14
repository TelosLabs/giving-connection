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
end

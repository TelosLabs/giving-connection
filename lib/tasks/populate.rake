namespace :populate do
  desc "Seed causes and services to DB"
  task seed_causes_and_services: :environment do
    Organizations::Constants::CAUSES_AND_SERVICES.each do |cause, services|
      new_cause = Cause.new(name: cause)
      print "." if new_cause.save
      services.each do |service|
        new_service = Service.new(name: service, cause: new_cause)

        puts "#{new_service.name} sucessfully created" if new_service.save!
      end
    end
    puts "Seeding Causes and Services to DB completed"
  end

  desc "Seed beneficiaries groups and subcategories to DB"
  task seed_beneficiaries_and_beneficiaries_subcategories: :environment do
    Organizations::Constants::BENEFICIARIES.each do |beneficiary, subbeneficiaries|
      new_beneficiary = BeneficiaryGroup.new(name: beneficiary)
      subbeneficiaries.each do |subbeneficiary|
        new_subbeneficiary = BeneficiarySubcategory.new(name: subbeneficiary, beneficiary_group: new_beneficiary)
        print '.' if new_subbeneficiary.save!
      end
    end
    puts "Seeding Beneficiaries and Beneficiaries Subcategories to DB completed"
  end
end

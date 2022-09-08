FactoryBot.define do
  factory :organization_beneficiary do
    organization { association(:organization) }
    beneficiary_subcategory { association(:beneficiary_subcategory) }
  end
end

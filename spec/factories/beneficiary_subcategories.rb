FactoryBot.define do
  factory :beneficiary_subcategory do
    name { 'Age' }
    beneficiary_group { association(:beneficiary_group) }
  end
end

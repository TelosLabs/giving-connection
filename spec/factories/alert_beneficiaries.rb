FactoryBot.define do
  factory :alert_beneficiary do
    alert { association(:alert) }
    beneficiary_subcategory { association(:beneficiary_subcategory) }
  end
end

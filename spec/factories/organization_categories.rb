FactoryBot.define do
  factory :organization_category do
    organization { association :organization }
    category { association :category }
  end
end

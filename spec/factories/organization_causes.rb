FactoryBot.define do
  factory :organization_cause do
    cause { create(:cause) }
  end
end

FactoryBot.define do
  factory :organization_cause do
    cause { create(:cause) }
    organization { association(:organization) }
  end
end

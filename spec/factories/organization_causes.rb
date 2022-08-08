FactoryBot.define do
  factory :organization_cause do
    cause { association(:cause) }
    organization { association(:organization) }
  end
end

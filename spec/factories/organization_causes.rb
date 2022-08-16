FactoryBot.define do
  factory :organization_causes do
    factory :organization_causes_skips_validate do
      to_create {|instance| instance.save(validate: false) }
    end
  end
end

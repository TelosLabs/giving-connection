FactoryBot.define do
  factory :service do
    name { "MyString" }
    description { "MyText" }
    organization { association :organization }
  end
end

FactoryBot.define do
  factory :location do
    name { 'MyString' }
    address { 'MyString' }
    latitude { 1.5 }
    longitude { 1.5 }
    organization { association(:organization) }
  end
end

require 'faker'

FactoryBot.define do
  factory :message do
    name { Faker::Name.name}            
    email { Faker::Internet.email }
    phone { Faker::PhoneNumber.cell_phone }
    subject { Faker::Lorem.sentence }
    organization_name { Faker::Company.name }
    organization_website { Faker::Internet.domain_name }
    organization_ein { Faker::Company.ein }
    content { Faker::Lorem.sentence }
  end
end

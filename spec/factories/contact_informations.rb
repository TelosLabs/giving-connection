# frozen_string_literal: true

FactoryBot.define do
  factory :contact_information do
    first_name { 'Ronaldo' }
    last_name { 'Nazario' }
    title { 'Founder' }
    email { 'ronaldo@email.com' }
    organization { association :organization }
  end
end

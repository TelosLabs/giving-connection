# frozen_string_literal: true

FactoryBot.define do
  factory :service do
    name { 'MyString' }
    description { 'MyText' }
    organization { association :organization }
  end
end

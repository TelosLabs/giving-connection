# frozen_string_literal: true

FactoryBot.define do
  factory :contact_information do
    first_name { 'MyString' }
    last_name { 'MyString' }
    title { 'MyString' }
    email { 'MyString' }
    organization { nil }
  end
end

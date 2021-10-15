# frozen_string_literal: true

FactoryBot.define do
  factory :subcategory do
    name { 'MyString' }
    organization { nil }
    category { nil }
  end
end

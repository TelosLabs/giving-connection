# frozen_string_literal: true

FactoryBot.define do
  factory :category do
    name { 'MyString' }
    subcategory { nil }
  end
end

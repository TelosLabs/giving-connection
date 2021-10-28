# frozen_string_literal: true

FactoryBot.define do
  factory :organization_category do
    organization { association :organization }
    category { association :category }
  end
end

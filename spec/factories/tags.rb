# frozen_string_literal: true

FactoryBot.define do
  factory :tag do
    name { 'Special Care' }
    organization { association :organization }
  end
end

# frozen_string_literal: true

FactoryBot.define do
  factory :admin_user do
    sequence(:email) { |n| "admin#{n}@example.com" }
    password { 'testing' }
    password_confirmation { 'testing' }
  end
end

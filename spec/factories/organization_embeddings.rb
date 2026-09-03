# frozen_string_literal: true

FactoryBot.define do
  factory :organization_embedding do
    organization
    embedding { Array.new(1024) { rand(-1.0..1.0) } }
    text_snapshot { "organization | testing | testing" }
  end
end

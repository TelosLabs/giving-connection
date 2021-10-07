# frozen_string_literal: true

FactoryBot.define do
  factory :phone_number do
    number { '+5521988381616' }
    main { true }
    contact_information { association :contact_information }
  end
end

# frozen_string_literal: true

# == Schema Information
#
# Table name: phone_numbers
#
#  id          :bigint           not null, primary key
#  number      :string
#  main        :boolean
#  location_id :bigint           not null
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#
FactoryBot.define do
  factory :phone_number do
    number { "MyString" }
    main { false }
    location { association :location, :appointment_only }
  end
end

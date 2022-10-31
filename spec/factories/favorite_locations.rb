# frozen_string_literal: true

# == Schema Information
#
# Table name: favorite_locations
#
#  id          :bigint           not null, primary key
#  user_id     :bigint           not null
#  location_id :bigint           not null
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#
FactoryBot.define do
  factory :favorite_location do
    user { association(:user) }
    location { association(:location) }
  end
end

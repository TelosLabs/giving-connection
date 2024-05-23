# frozen_string_literal: true

# == Schema Information
#
# Table name: location_services
#
#  id          :bigint           not null, primary key
#  description :string
#  location_id :bigint           not null
#  service_id  :bigint           not null
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#
FactoryBot.define do
  factory :location_service do
    location { create(:location, :with_office_hours) }
    service
  end
end

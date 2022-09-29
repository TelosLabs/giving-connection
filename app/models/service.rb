# frozen_string_literal: true

# == Schema Information
#
# Table name: services
#
#  id         :bigint           not null, primary key
#  name       :string
#  cause_id   :bigint           not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
class Service < ApplicationRecord
  belongs_to :cause
  has_many :location_services, dependent: :destroy
  has_many :locations, through: :location_services

  def self.most_repeated_in_locations
    services_count = {}
    Location.all.each do |location|
      location.services.each do |service|
        services_count[service] = services_count[service].to_i + 1
      end
    end
    arr = services_count.sort_by { |service, count| count }.reverse.first(10)
    arr.map { |service, count| service }
  end
end

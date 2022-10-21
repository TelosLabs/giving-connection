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

  def self.top_10_services
    arr = Location.all.map(&:services).flatten.tally.sort_by { |_service, count| count }.reverse.first(10)
    arr.map { |service, _count| service }
  end
end

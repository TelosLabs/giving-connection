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
    Location.joins(:services).group(:service_id).order('count(service_id) desc').limit(10).pluck(:service_id).map { |id| Service.find(id) }
  end
end

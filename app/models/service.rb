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

  validates :name, presence: true, uniqueness: true
end

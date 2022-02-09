# frozen_string_literal: true

# == Schema Information
#
# Table name: causes
#
#  id         :bigint           not null, primary key
#  name       :string
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
class Cause < ApplicationRecord
  has_many :services
  has_many :location_causes, dependent: :destroy
  has_many :locations, through: :location_causes
end

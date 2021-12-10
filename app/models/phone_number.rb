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
class PhoneNumber < ApplicationRecord
  belongs_to :location
end

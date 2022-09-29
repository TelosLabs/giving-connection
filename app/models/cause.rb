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

  def self.most_repeated_in_locations
    causes_count = {}
    Location.all.each do |location|
      location.causes.each do |cause|
        causes_count[cause] = causes_count[cause].to_i + 1
      end
    end
    arr = causes_count.sort_by { |cause, count| count }.reverse.first(10)
    arr.map { |cause, count| cause }
  end
end

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
  # scope :top_10_causes, -> { Location.all.map(&:causes).flatten.tally.sort_by { |_cause, count| count }.reverse.first(10).map { |cause, _count| cause } }

  # As a method
  def self.top_10_causes
    arr = Location.all.map(&:causes).flatten.tally.sort_by { |_cause, count| count }.reverse.first(10)
    arr.map { |cause, _count| cause }
  end
end

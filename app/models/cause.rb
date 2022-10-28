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

  def self.top_10_causes
    # This comment ws used for testing
    Location.joins(:causes).group(:cause_id).order('count(cause_id) desc').limit(10).pluck(:cause_id).map { |id| Cause.find(id) }
  end
end

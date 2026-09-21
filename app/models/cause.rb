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
  include PgSearch::Model
  multisearchable against: :name
  has_many :organization_causes, dependent: :destroy
  has_many :organizations, through: :organization_causes
  has_many :services

  validates :name, presence: true, uniqueness: true

  # Cause names/services are cached for a day in SearchesController and
  # SelectMultiple::Component; bust it immediately on
  # write instead of leaving up to a day of staleness after an admin edit.
  after_commit -> { Rails.cache.delete_multi(%w[search_pills/causes search_pills/services select_multiple/causes_with_services]) }

  def to_param
    name
  end

  def self.top(limit: 10)
    find(top_causes_ids(limit: limit))
  end

  def self.top_causes_ids(limit: 10)
    OrganizationCause.group(:cause_id).order("count(cause_id) desc").limit(limit).count.keys
  end
end

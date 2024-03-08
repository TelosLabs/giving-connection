# frozen_string_literal: true

# == Schema Information
#
# Table name: tags
#
#  id              :bigint           not null, primary key
#  name            :string
#  organization_id :bigint           not null
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#
class Tag < ApplicationRecord
  include PgSearch::Model
  belongs_to :organization

  pg_search_scope :search_suggestions, against: :name,
                                       using: {
                                         tsearch: { prefix: true },
                                         trigram: { threshold: 0.2 }
                                       }

  def self.suggestions(term)
    search_suggestions(term).pluck(:name).uniq.map(&:downcase)
  end
end

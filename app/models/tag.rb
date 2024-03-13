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
  multisearchable against: :name
end

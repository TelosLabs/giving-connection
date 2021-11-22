# frozen_string_literal: true

# == Schema Information
#
# Table name: social_medias
#
#  id              :bigint           not null, primary key
#  facebook        :string
#  instagram       :string
#  twitter         :string
#  linkedin        :string
#  youtube         :string
#  blog            :string
#  organization_id :bigint           not null
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#
class SocialMedia < ApplicationRecord
  belongs_to :organization
end

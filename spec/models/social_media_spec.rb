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
require 'rails_helper'

RSpec.describe SocialMedia, type: :model do
  context 'Social Media model validation test' do
    subject { create(:social_media) }

    it 'ensures social media can be created' do
      expect(subject).to be_valid
    end
  end
end

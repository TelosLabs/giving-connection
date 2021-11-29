# frozen_string_literal: true

# == Schema Information
#
# Table name: organizations
#
#  id                   :bigint           not null, primary key
#  name                 :string           not null
#  ein_number           :string           not null
#  irs_ntee_code        :string           not null
#  website              :string
#  scope_of_work        :string           not null
#  creator_type         :string
#  creator_id           :bigint
#  created_at           :datetime         not null
#  updated_at           :datetime         not null
#  mission_statement_en :text             not null
#  mission_statement_es :text
#  vision_statement_en  :text             not null
#  vision_statement_es  :text
#  tagline_en           :text             not null
#  tagline_es           :text
#
require 'rails_helper'

RSpec.describe Organization, type: :model do
  context 'Organization model validation test' do
    subject { create(:organization) }

    it 'ensures organizations can be created' do
      expect(subject).to be_valid
    end

    it 'attaches a default logo' do
      expect(subject.logo.attached?).to eq(true)
    end

    it 'attaches a default cover photo' do
      expect(subject.cover_photo.attached?).to eq(true)
    end
  end
end

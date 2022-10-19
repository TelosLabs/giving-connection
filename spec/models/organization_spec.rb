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
#  second_name          :string
#  phone_number         :string
#  email                :string
#
require 'rails_helper'

RSpec.describe Organization, type: :model do
  subject { create(:organization) }

  describe "Associations" do
    it { should have_many(:tags).dependent(:destroy) }
    it { should have_many(:organization_causes).dependent(:destroy) }
    it { should have_many(:causes) }
    it { should have_many(:organization_beneficiaries).dependent(:destroy) }
    it { should have_many(:organization_admins).dependent(:destroy) }
    it { should have_many(:beneficiary_subcategories) }
    it { should have_many(:locations).dependent(:destroy) }
    it { should have_many(:additional_locations).conditions(main: false) }
    it { should have_one(:main_location).conditions(main: true) }
    it { should have_one(:social_media).dependent(:destroy) }
    it { should have_one_attached(:logo) }
    it { should have_one_attached(:cover_photo) }
    it { should belong_to(:creator) }
  end

  describe "Validations" do
    it { should validate_presence_of(:name) }
    it { should validate_presence_of(:causes) }
    it { should validate_presence_of(:ein_number) }
    it { should validate_uniqueness_of(:ein_number) }
    it { should validate_presence_of(:irs_ntee_code) }
    it { should validate_inclusion_of(:irs_ntee_code).in_array( Organizations::Constants::NTEE_CODE ) }
    it { should validate_presence_of(:mission_statement_en) }
    it { should validate_presence_of(:scope_of_work) }
    it { should validate_inclusion_of(:scope_of_work).in_array( Organizations::Constants::SCOPE ) }
    #it { should validate_logo_content_type }
  end
end

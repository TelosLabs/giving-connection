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
require "rails_helper"

RSpec.describe Organization, type: :model do
  subject { create(:organization) }

  describe "Associations" do
    it { is_expected.to have_many(:tags).dependent(:destroy) }
    it { is_expected.to have_many(:organization_causes).dependent(:destroy) }
    it { is_expected.to have_many(:causes) }
    it { is_expected.to have_many(:organization_beneficiaries).dependent(:destroy) }
    it { is_expected.to have_many(:organization_admins).dependent(:destroy) }
    it { is_expected.to have_many(:beneficiary_subcategories) }
    it { is_expected.to have_many(:locations).dependent(:destroy) }
    it { is_expected.to have_many(:additional_locations).conditions(main: false) }
    it { is_expected.to have_one(:main_location).conditions(main: true) }
    it { is_expected.to have_one(:social_media).dependent(:destroy) }
    it { is_expected.to have_one_attached(:logo) }
    it { is_expected.to have_one_attached(:cover_photo) }
    it { is_expected.to belong_to(:creator) }
  end

  describe "Validations" do
    it { is_expected.to validate_presence_of(:name) }
    it { is_expected.to validate_presence_of(:organization_causes) }
    it { is_expected.to validate_presence_of(:ein_number) }
    it { is_expected.to validate_uniqueness_of(:ein_number) }
    it { is_expected.to validate_presence_of(:irs_ntee_code) }
    it { is_expected.to validate_inclusion_of(:irs_ntee_code).in_array(Organizations::Constants::NTEE_CODE) }
    it { is_expected.to validate_presence_of(:mission_statement_en) }
    it { is_expected.to validate_presence_of(:scope_of_work) }
    it { is_expected.to validate_inclusion_of(:scope_of_work).in_array(Organizations::Constants::SCOPE) }
  end
end

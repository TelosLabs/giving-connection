# frozen_string_literal: true

# == Schema Information
#
# Table name: alerts
#
#  id                 :bigint           not null, primary key
#  user_id            :bigint           not null
#  distance           :string
#  city               :string
#  state              :string
#  services           :string
#  open_now           :string
#  open_weekends      :string
#  keyword            :string
#  beneficiary_groups :string
#  frequency          :string           default("weekly")
#  created_at         :datetime         not null
#  updated_at         :datetime         not null
#  next_alert         :date
#
require 'rails_helper'

RSpec.describe Alert, type: :model do
  subject { create(:alert) }

  describe "associations" do
    it { should belong_to(:user) }
    it { should have_many(:alert_services).dependent(:destroy) }
    it { should have_many(:alert_beneficiaries).dependent(:destroy) }
    it { should have_many(:alert_causes).dependent(:destroy) }
  end

  describe "validations" do
    it { should validate_presence_of(:frequency) }
    it { should validate_inclusion_of(:frequency).in_array( %w[daily weekly monthly] ) }
  end
end

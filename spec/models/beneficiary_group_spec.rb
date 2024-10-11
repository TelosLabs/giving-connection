# frozen_string_literal: true

# == Schema Information
#
# Table name: beneficiary_groups
#
#  id         :bigint           not null, primary key
#  name       :string
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
require "rails_helper"

RSpec.describe BeneficiaryGroup, type: :model do
  describe "associations" do
    subject { create(:beneficiary_group) }

    it { is_expected.to have_many(:beneficiary_subcategories).dependent(:destroy) }
  end
end

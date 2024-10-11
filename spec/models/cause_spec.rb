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
require "rails_helper"

RSpec.describe Cause, type: :model do
  describe "associations" do
    subject { create(:cause) }

    it { is_expected.to have_many(:organization_causes).dependent(:destroy) }
    it { is_expected.to have_many(:organizations).through(:organization_causes) }
    it { is_expected.to have_many(:services) }
  end
end

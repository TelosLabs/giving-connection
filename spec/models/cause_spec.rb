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
require 'rails_helper'

RSpec.describe Cause, type: :model do
  describe "associations" do
    subject { create(:cause) }

    it { should have_many(:organization_causes).dependent(:destroy) }
    it { should have_many(:organizations).through(:organization_causes) }
    it { should have_many(:services) }
  end
end

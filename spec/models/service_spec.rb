# frozen_string_literal: true

# == Schema Information
#
# Table name: services
#
#  id         :bigint           not null, primary key
#  name       :string
#  cause_id   :bigint           not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
require 'rails_helper'

RSpec.describe Service, type: :model do
  describe "associations" do
    subject { create(:service) }

    it { should belong_to(:cause) }
    it { should have_many(:location_services).dependent(:destroy) }
    it { should have_many(:locations).through(:location_services) }
  end
end

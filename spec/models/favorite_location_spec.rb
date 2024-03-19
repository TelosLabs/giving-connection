# frozen_string_literal: true

# == Schema Information
#
# Table name: favorite_locations
#
#  id          :bigint           not null, primary key
#  user_id     :bigint           not null
#  location_id :bigint           not null
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#
require "rails_helper"

RSpec.describe FavoriteLocation, type: :model do
  context "FavoriteLocation model validation test" do
    subject { create(:favorite_location) }

    it "ensures favorite_location can be created" do
      expect(subject).to be_valid
    end
  end
end

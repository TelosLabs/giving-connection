# frozen_string_literal: true

# == Schema Information
#
# Table name: tags
#
#  id              :bigint           not null, primary key
#  name            :string
#  organization_id :bigint           not null
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#
require "rails_helper"

RSpec.describe Tag, type: :model do
  context "Tag model validation test" do
    subject { create(:tag) }

    it "ensures tags can be created" do
      expect(subject).to be_valid
    end
  end
end

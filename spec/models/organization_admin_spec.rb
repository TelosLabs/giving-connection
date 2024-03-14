# frozen_string_literal: true

# == Schema Information
#
# Table name: organization_admins
#
#  id              :bigint           not null, primary key
#  organization_id :bigint           not null
#  user_id         :bigint           not null
#  role            :string
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#
require "rails_helper"

RSpec.describe OrganizationAdmin, type: :model do
  context "OrganizationAdmin model validation test" do
    subject { create(:organization_admin) }

    it "ensures organization_admin can be created" do
      expect(subject).to be_valid
    end
  end
end

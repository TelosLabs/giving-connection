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

  describe "search index sync" do
    it "enqueues a search_vector refresh on create" do
      org = create(:organization)
      allow(Locations::RefreshSearchVectorJob).to receive(:coalesce_for_organization)

      create(:tag, organization: org)

      expect(Locations::RefreshSearchVectorJob).to have_received(:coalesce_for_organization).with(org.id)
    end

    it "enqueues a search_vector refresh on destroy" do
      org = create(:organization)
      tag = create(:tag, organization: org)
      allow(Locations::RefreshSearchVectorJob).to receive(:coalesce_for_organization)

      tag.destroy

      expect(Locations::RefreshSearchVectorJob).to have_received(:coalesce_for_organization).with(org.id)
    end
  end
end

# frozen_string_literal: true

# == Schema Information
#
# Table name: social_medias
#
#  id              :bigint           not null, primary key
#  facebook        :string
#  instagram       :string
#  twitter         :string
#  linkedin        :string
#  youtube         :string
#  blog            :string
#  organization_id :bigint           not null
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#
require "rails_helper"

RSpec.describe SocialMedia, type: :model do
  context "Social Media model validation test" do
    subject { create(:social_media) }

    it "ensures social media can be created" do
      expect(subject).to be_valid
    end
  end

  describe "search index sync" do
    it "enqueues a search_vector refresh on create" do
      org = create(:organization)
      allow(Locations::RefreshSearchVectorJob).to receive(:coalesce_for_organization)

      create(:social_media, organization: org)

      expect(Locations::RefreshSearchVectorJob).to have_received(:coalesce_for_organization).with(org.id)
    end

    it "enqueues a search_vector refresh on update" do
      org = create(:organization)
      social_media = create(:social_media, organization: org)
      allow(Locations::RefreshSearchVectorJob).to receive(:coalesce_for_organization)

      social_media.update!(facebook: "facebook.com/new-handle")

      expect(Locations::RefreshSearchVectorJob).to have_received(:coalesce_for_organization).with(org.id)
    end
  end
end

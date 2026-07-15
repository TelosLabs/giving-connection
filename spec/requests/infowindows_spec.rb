# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Infowindows", type: :request do
  let(:organization) { create(:organization) }
  let(:location) { organization.locations.first }
  let(:frame_id) { "loc_#{location.id}" }

  describe "GET /infowindow/new" do
    it "renders the turbo-frame for an organization with default media" do
      expect(organization.logo).to be_attached

      get new_infowindow_path(frame_id: frame_id)

      expect(response).to have_http_status(:ok)
      expect(response.body).to include(%(id="#{frame_id}"))
      expect(response.body.downcase).not_to include("content missing")
    end

    context "when the organization is missing its logo (e.g. bulk-imported)" do
      before do
        organization.logo.purge
        organization.cover_photo.purge
      end

      it "renders once default media is ensured" do
        organization.ensure_default_media!

        get new_infowindow_path(frame_id: frame_id)

        expect(response).to have_http_status(:ok)
        expect(response.body).to include(%(id="#{frame_id}"))
        expect(response.body).to include("<img")
      end
    end
  end
end

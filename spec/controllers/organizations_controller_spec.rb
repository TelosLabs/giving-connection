# frozen_string_literal: true

require "rails_helper"

RSpec.describe Admin::OrganizationsController, type: :controller do
  let(:organization) { create(:organization) }

  before do
    @admin = create(:admin_user)
    @params = {name: "organization", ein_number: "testing", irs_ntee_code: "A90",
               mission_statement_en: "testing", mission_statement_es: "pruebas",
               vision_statement_en: "testing", vision_statement_es: "pruebas",
               tagline_en: "testing", tagline_es: "pruebas",
               website: "testing", scope_of_work: "International"}
  end

  describe "GET #index" do
    context "when not logged in" do
      it "redirects to new admin user session" do
        get :new
        expect(response).to redirect_to admin_user_session_path
      end

      it "responses with 302 status code" do
        get :new
        expect(response).to have_http_status(:found)
      end
    end

    context "when logged in" do
      before { sign_in @admin }

      it "renders the new template" do
        get :new
        expect(response).to render_template(:new)
      end

      it "responses with 200 status code" do
        get :new
        expect(response).to have_http_status(:ok)
      end
    end
  end

  describe "GET #show" do
    context "when user logged in" do
      before { sign_in @admin }

      it "should sucessfully render organizations dashboard show page" do
        get :show, params: {id: organization.id}
        expect(response).to have_http_status(:ok)
        expect(response).to render_template(:show)
      end

      it "responses with 200 status code" do
        get :new
        expect(response).to have_http_status(:ok)
      end
    end
  end

  describe "GET #new" do
    context "when not logged in" do
      it "redirects to new user session" do
        get :new
        expect(response).to redirect_to admin_user_session_path
      end

      it "responses with 302 status code" do
        get :new
        expect(response).to have_http_status(:found)
      end
    end

    context "when logged in" do
      before { sign_in @admin }

      it "renders the new template" do
        get :new
        expect(response).to render_template(:new)
      end

      it "responses with 200 status code" do
        get :new
        expect(response).to have_http_status(:ok)
      end
    end
  end

  describe "PATCH #update" do
    before { sign_in @admin }

    def patch_update(organization_attributes)
      patch :update, params: {id: organization.id, tags_attributes: "", organization: organization_attributes}
    end

    it "collects in-kind donation items through the dashboard's permitted attributes" do
      patch_update(in_kind_donation_items: ["", "diapers", "diapers"])

      expect(organization.reload.in_kind_donation_items).to eq(["diapers"])
    end

    it "ignores in-kind donation items sent as a scalar instead of an array" do
      organization.update!(in_kind_donation_items: ["diapers"])

      patch_update(in_kind_donation_items: "shoes")

      expect(organization.reload.in_kind_donation_items).to eq(["diapers"])
    end

    it "re-renders the form for an unsupported item" do
      patch_update(in_kind_donation_items: ["not-supported"])

      expect(response).to have_http_status(:unprocessable_entity)
      expect(organization.reload.in_kind_donation_items).to eq([])
    end
  end
end

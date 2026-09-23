# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Admin::SearchTerms", type: :request do
  let(:admin) { create(:admin_user) }

  # Search terms are a record of what visitors typed into the site, so browsing
  # them has to be closed to anyone who is not an AdminUser.
  describe "authorization" do
    shared_examples "denied" do
      it "redirects the index away from the admin" do
        get admin_search_terms_path
        expect(response).to redirect_to(new_admin_user_session_path)
      end

      it "redirects the show page away from the admin" do
        search_term = create(:search_term)
        get admin_search_term_path(search_term)
        expect(response).to redirect_to(new_admin_user_session_path)
      end
    end

    context "when signed out" do
      include_examples "denied"
    end

    context "when signed in as a regular user" do
      before { login_as(create(:user), scope: :user) }

      include_examples "denied"
    end
  end

  # The section is view-only: search terms are recorded automatically, so the
  # admin never creates, edits or destroys them.
  describe "routing" do
    it "does not expose create, edit, update or destroy routes" do
      expect { new_admin_search_term_path }.to raise_error(NameError)
      expect { edit_admin_search_term_path(1) }.to raise_error(NameError)
    end
  end

  context "when signed in as an admin" do
    before { login_as(admin, scope: :admin_user) }

    describe "GET /admin/search_terms" do
      it "lists the search terms" do
        create(:search_term, keyword: "food pantry")
        get admin_search_terms_path

        expect(response).to have_http_status(:ok)
        expect(response.body).to include("food pantry")
      end

      it "orders the most recent searches first" do
        create(:search_term, keyword: "older term", created_at: 2.days.ago)
        create(:search_term, keyword: "newer term")

        get admin_search_terms_path

        expect(response.body.index("newer term")).to be < response.body.index("older term")
      end

      it "searches by keyword" do
        create(:search_term, keyword: "food pantry")
        create(:search_term, keyword: "legal aid")

        get admin_search_terms_path(search: "food")

        expect(response).to have_http_status(:ok)
        expect(response.body).to include("food pantry")
        expect(response.body).not_to include("legal aid")
      end
    end

    describe "GET /admin/search_terms/:id" do
      it "renders the search term" do
        search_term = create(:search_term, keyword: "food pantry")
        get admin_search_term_path(search_term)

        expect(response).to have_http_status(:ok)
        expect(response.body).to include("food pantry")
      end
    end
  end
end

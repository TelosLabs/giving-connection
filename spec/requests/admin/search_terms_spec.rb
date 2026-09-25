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

      it "redirects the CSV export away from the admin" do
        get admin_search_terms_path(format: :csv)
        expect(response).not_to have_http_status(:ok)
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

      context "with date range filters" do
        it "shows only search terms created on or after date_from" do
          create(:search_term, keyword: "before range", created_at: Date.new(2024, 1, 5))
          create(:search_term, keyword: "in range", created_at: Date.new(2024, 1, 15))

          get admin_search_terms_path(date_from: "2024-01-10")

          expect(response.body).to include("in range")
          expect(response.body).not_to include("before range")
        end

        it "shows only search terms created on or before date_to (inclusive of that day)" do
          create(:search_term, keyword: "in range", created_at: Date.new(2024, 1, 15))
          create(:search_term, keyword: "after range", created_at: Date.new(2024, 1, 25))

          get admin_search_terms_path(date_to: "2024-01-20")

          expect(response.body).to include("in range")
          expect(response.body).not_to include("after range")
        end

        it "applies both bounds together" do
          create(:search_term, keyword: "too early", created_at: Date.new(2024, 1, 1))
          create(:search_term, keyword: "in range", created_at: Date.new(2024, 1, 15))
          create(:search_term, keyword: "too late", created_at: Date.new(2024, 2, 1))

          get admin_search_terms_path(date_from: "2024-01-10", date_to: "2024-01-20")

          expect(response.body).to include("in range")
          expect(response.body).not_to include("too early")
          expect(response.body).not_to include("too late")
        end

        it "ignores malformed date params rather than raising" do
          create(:search_term, keyword: "food pantry")

          get admin_search_terms_path(date_from: "not-a-date")

          expect(response).to have_http_status(:ok)
          expect(response.body).to include("food pantry")
        end
      end
    end

    describe "GET /admin/search_terms.csv" do
      it "returns a CSV file with the correct content type and headers" do
        create(:search_term)
        get admin_search_terms_path(format: :csv)

        expect(response).to have_http_status(:ok)
        expect(response.media_type).to eq("text/csv")
        expect(response.body).to include(SearchTerm::CSV_HEADERS.first)
      end

      it "includes the record data" do
        create(:search_term, keyword: "food pantry", city: "Nashville", state: "TN")
        get admin_search_terms_path(format: :csv)

        expect(response.body).to include("food pantry")
        expect(response.body).to include("Nashville")
        expect(response.body).to include("TN")
      end

      it "honors the active search filter so the download matches the visible rows" do
        create(:search_term, keyword: "food pantry")
        create(:search_term, keyword: "legal aid")

        get admin_search_terms_path(format: :csv, search: "food")

        expect(response.body).to include("food pantry")
        expect(response.body).not_to include("legal aid")
      end

      it "orders by created_at descending by default, matching the index page" do
        create(:search_term, keyword: "older term", created_at: 2.days.ago)
        create(:search_term, keyword: "newer term")

        get admin_search_terms_path(format: :csv)

        expect(response.body.index("newer term")).to be < response.body.index("older term")
      end

      it "honors column sort params so the download matches the sorted index page" do
        create(:search_term, keyword: "zoo search")
        create(:search_term, keyword: "aardvark search")

        get admin_search_terms_path(format: :csv, search_term: {order: "keyword", direction: "asc"})

        expect(response.body.index("aardvark search")).to be < response.body.index("zoo search")
      end

      it "applies the date_from filter to the export" do
        create(:search_term, keyword: "before range", created_at: Date.new(2024, 1, 5))
        create(:search_term, keyword: "in range", created_at: Date.new(2024, 1, 15))

        get admin_search_terms_path(format: :csv, date_from: "2024-01-10")

        expect(response.body).to include("in range")
        expect(response.body).not_to include("before range")
      end

      it "applies the date_to filter to the export" do
        create(:search_term, keyword: "in range", created_at: Date.new(2024, 1, 15))
        create(:search_term, keyword: "after range", created_at: Date.new(2024, 1, 25))

        get admin_search_terms_path(format: :csv, date_to: "2024-01-20")

        expect(response.body).to include("in range")
        expect(response.body).not_to include("after range")
      end

      it "applies both date bounds together to the export" do
        create(:search_term, keyword: "too early", created_at: Date.new(2024, 1, 1))
        create(:search_term, keyword: "in range", created_at: Date.new(2024, 1, 15))
        create(:search_term, keyword: "too late", created_at: Date.new(2024, 2, 1))

        get admin_search_terms_path(format: :csv, date_from: "2024-01-10", date_to: "2024-01-20")

        expect(response.body).to include("in range")
        expect(response.body).not_to include("too early")
        expect(response.body).not_to include("too late")
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

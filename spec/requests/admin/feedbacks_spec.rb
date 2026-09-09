# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Admin::Feedbacks", type: :request do
  let(:admin) { create(:admin_user) }

  # Feedback contains free-text comments and the submitter's email, and the
  # mark-read actions mutate it, so everything under /admin/feedbacks has to be
  # closed to anyone who is not an AdminUser.
  describe "authorization" do
    shared_examples "denied" do
      it "redirects the index away from the admin" do
        get admin_feedbacks_path
        expect(response).to redirect_to(new_admin_user_session_path)
      end

      it "redirects the CSV export away from the admin" do
        get admin_feedbacks_path(format: :csv)
        expect(response).not_to have_http_status(:ok)
      end

      it "does not mark feedback as read" do
        feedback = create(:feedback, read_at: nil)
        patch mark_as_read_admin_feedback_path(feedback)

        expect(response).to redirect_to(new_admin_user_session_path)
        expect(feedback.reload).not_to be_read
      end

      it "does not mark every feedback as read" do
        create_list(:feedback, 2, read_at: nil)
        patch mark_all_as_read_admin_feedbacks_path

        expect(Feedback.unread.count).to eq(2)
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

  context "when signed in as an admin" do
    before { login_as(admin, scope: :admin_user) }

    describe "GET /admin/feedbacks" do
      it "lists the feedback" do
        create(:feedback, comment: "Loved the search")
        get admin_feedbacks_path

        expect(response).to have_http_status(:ok)
      end

      # `read` and `email` are virtual attributes, not columns, but Administrate
      # renders sortable headers for every collection attribute. Clicking them
      # must not blow up with a PG::UndefinedColumn.
      it "survives sorting by the virtual columns" do
        create_list(:feedback, 2)

        %w[read email].each do |column|
          get admin_feedbacks_path(order: column, direction: "asc")
          expect(response).to have_http_status(:ok), "sorting by #{column} failed"
        end
      end

      # Same hazard on the search side: Administrate builds one LIKE per
      # searchable collection attribute, and `email` has no column behind it.
      it "searches by term without touching the virtual columns" do
        create(:feedback, page_url: "https://example.com/search?q=matching")
        create(:feedback, page_url: "https://example.com/other")

        get admin_feedbacks_path(search: "matching")

        expect(response).to have_http_status(:ok)
        expect(response.body).to include("q=matching")
        expect(response.body).not_to include("example.com/other")
      end

      it "applies the unread: collection filter" do
        create(:feedback, page_url: "https://example.com/still-unread", read_at: nil)
        create(:feedback, page_url: "https://example.com/already-seen", read_at: Time.current)

        get admin_feedbacks_path(search: "unread:")

        expect(response).to have_http_status(:ok)
        expect(response.body).to include("still-unread")
        expect(response.body).not_to include("already-seen")
      end
    end

    describe "GET /admin/feedbacks.csv" do
      it "returns a CSV export with the feedback headers" do
        create(:feedback)
        get admin_feedbacks_path(format: :csv)

        expect(response).to have_http_status(:ok)
        expect(response.media_type).to eq("text/csv")
        expect(response.body).to include(Feedback::CSV_HEADERS.first)
      end

      # The export has to match the rows the admin is looking at, otherwise
      # narrowing the inbox and hitting "Download CSV" quietly dumps every row
      # and every submitter email.
      it "honors the active collection filter" do
        create(:feedback, comment: "Unread one", read_at: nil)
        create(:feedback, comment: "Read one", read_at: Time.current)

        get admin_feedbacks_path(format: :csv, search: "unread:")

        expect(response).to have_http_status(:ok)
        expect(response.body).to include("Unread one")
        expect(response.body).not_to include("Read one")
      end

      it "honors a search term" do
        create(:feedback, comment: "Maps were confusing")
        create(:feedback, comment: "Everything worked")

        get admin_feedbacks_path(format: :csv, search: "confusing")

        expect(response).to have_http_status(:ok)
        expect(response.body).to include("Maps were confusing")
        expect(response.body).not_to include("Everything worked")
      end
    end

    describe "GET /admin/feedbacks/:id" do
      it "marks the feedback as read as a side effect of viewing" do
        feedback = create(:feedback, read_at: nil)
        get admin_feedback_path(feedback)

        expect(response).to have_http_status(:ok)
        expect(feedback.reload.read_at).to be_present
      end
    end

    describe "PATCH mark_as_read / mark_as_unread" do
      it "marks an unread feedback as read" do
        feedback = create(:feedback, read_at: nil)
        patch mark_as_read_admin_feedback_path(feedback)

        expect(response).to redirect_to(admin_feedbacks_path)
        expect(feedback.reload).to be_read
      end

      it "marks a read feedback as unread" do
        feedback = create(:feedback, read_at: Time.current)
        patch mark_as_unread_admin_feedback_path(feedback)

        expect(feedback.reload).not_to be_read
      end
    end

    describe "PATCH mark_all_as_read" do
      it "marks every unread feedback as read" do
        create_list(:feedback, 3, read_at: nil)
        patch mark_all_as_read_admin_feedbacks_path

        expect(response).to redirect_to(admin_feedbacks_path)
        expect(Feedback.unread).to be_empty
      end

      it "pluralizes the notice" do
        create(:feedback, read_at: nil)
        patch mark_all_as_read_admin_feedbacks_path

        expect(flash[:notice]).to eq("1 feedback entry marked as read.")
      end
    end
  end
end

# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Admin::Feedbacks", type: :request do
  let(:admin) { create(:admin_user) }

  before { login_as(admin, scope: :admin_user) }

  describe "GET /admin/feedbacks.csv" do
    it "returns a CSV export with the feedback headers" do
      create(:feedback)
      get admin_feedbacks_path(format: :csv)

      expect(response).to have_http_status(:ok)
      expect(response.media_type).to eq("text/csv")
      expect(response.body).to include(Feedback::CSV_HEADERS.first)
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
  end
end

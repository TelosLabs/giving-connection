# frozen_string_literal: true

module Admin
  class FeedbacksController < Admin::ApplicationController
    # Feedback records are created by end users; admins browse them like an
    # inbox and mark them read/unread. See FeedbackDashboard for the fields.

    # Most-recent feedback first on the index page.
    def scoped_resource
      super.order(created_at: :desc)
    end

    # Add a CSV export of all feedback alongside the standard index view.
    def index
      if request.format.csv?
        send_data Feedback.to_csv,
                  filename: "feedback-#{Time.zone.today.iso8601}.csv",
                  type: "text/csv"
      else
        super
      end
    end

    # Opening a feedback marks it as read, like an inbox.
    def show
      requested_resource.mark_as_read!
      super
    end

    def mark_as_read
      requested_resource.mark_as_read!
      redirect_back fallback_location: admin_feedbacks_path, notice: "Feedback marked as read."
    end

    def mark_as_unread
      requested_resource.mark_as_unread!
      redirect_back fallback_location: admin_feedbacks_path, notice: "Feedback marked as unread."
    end

    def mark_all_as_read
      count = Feedback.unread.update_all(read_at: Time.current)
      redirect_to admin_feedbacks_path, notice: "#{count} feedback marked as read."
    end
  end
end

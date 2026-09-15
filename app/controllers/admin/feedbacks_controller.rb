# frozen_string_literal: true

module Admin
  class FeedbacksController < Admin::ApplicationController
    # Feedback records are created by end users; admins browse them like an
    # inbox and mark them read/unread. See FeedbackDashboard for the fields.

    # Most-recent feedback first on the index page. The index renders each row's
    # submitter email, so preload the users to avoid a query per row.
    def scoped_resource
      super.includes(:user).order(created_at: :desc)
    end

    # Add a CSV export alongside the standard index view. The export runs through
    # the same search/filter pipeline as the HTML index (see Administrate's
    # #index), so "Download CSV" gives the admin the rows they are looking at,
    # not the whole table plus every submitter email.
    def index
      if request.format.csv?
        send_data csv_export_scope.to_csv,
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
      redirect_to admin_feedbacks_path, notice: "#{helpers.pluralize(count, "feedback entry")} marked as read."
    end

    private

    def csv_export_scope
      filter_resources(scoped_resource, search_term: params[:search].to_s.strip)
        .unscope(:order)
    end
  end
end

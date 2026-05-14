# frozen_string_literal: true

module SmartMatch
  class ResultsController < ApplicationController
    skip_before_action :authenticate_user!
    skip_after_action :verify_authorized
    skip_after_action :verify_policy_scoped

    def show
      @user_type = session[:smart_match_user_type]
      process_quiz_results if quiz_completed?
    rescue SmartMatch::EmbeddingUnavailableError
      @embedding_unavailable = true
    rescue PG::Error, ActiveRecord::RecordInvalid, Net::HTTPFatalError => e
      Rails.logger.error("[SmartMatch::ResultsController] #{e.class}: #{e.message}")
      @embedding_unavailable = true
    rescue => e
      Rails.logger.error("[SmartMatch::ResultsController] Unexpected #{e.class}: #{e.message}\n#{e.backtrace&.first(10)&.join("\n")}")
      @embedding_unavailable = true
    end

    private

    def quiz_completed?
      session[:smart_match_user_type].present? && session[:smart_match_causes].present?
    end

    def process_quiz_results
      @submission = find_or_create_submission
      return unless @submission

      @results = @submission.organization_matches
        .includes(organization: [:causes, :main_location, {logo_attachment: :blob}, {cover_photo_attachment: :blob}])
        .order(:rank)
        .limit(3)
    end

    def find_or_create_submission
      if (id = session[:smart_match_submission_id])
        submission = QuizSubmission.find_by(id: id)
        return submission if submission

        # Cached submission id is stale (cleared from DB, different env, etc).
        # Sending the user back to the landing page is safer than silently
        # rebuilding a submission they may not be expecting.
        session.delete(:smart_match_submission_id)
        flash[:alert] = "Your previous results expired. Please retake the quiz."
        redirect_to smart_match_root_path and return nil
      end

      create_submission
    end

    def create_submission
      result = SmartMatch::SubmissionProcessor.call(
        session_answers: submission_attributes,
        user_type: session[:smart_match_user_type],
        session_id: session.id.to_s,
        user: current_user
      )
      submission = result[:submission]
      session[:smart_match_submission_id] = submission.id
      submission
    end

    def submission_attributes
      {
        state: session[:smart_match_state],
        city: session[:smart_match_city],
        travel_bucket: session[:smart_match_travel_bucket],
        causes: session[:smart_match_causes],
        prefs: session[:smart_match_prefs],
        language_input: session[:smart_match_language]
      }
    end
  end
end

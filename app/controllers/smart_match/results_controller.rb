# frozen_string_literal: true

module SmartMatch
  class ResultsController < ApplicationController
    skip_before_action :authenticate_user!
    skip_after_action :verify_authorized
    skip_after_action :verify_policy_scoped

    def show
      @user_type = session[:smart_match_user_type]
      return unless quiz_completed?

      @submission = find_submission
      return if performed? # stale-id redirect already happened

      if @submission
        @results = matches_for(@submission)
      elsif processing_error?
        # Terminal failure recorded by the background job. Clear the flags so
        # the "try again" link starts a fresh attempt, then degrade gracefully.
        reset_processing_state
        @embedding_unavailable = true
      else
        # Embedding + scoring runs off the request thread (see
        # ProcessSubmissionJob) so a slow embedding service can't block Puma.
        # Render the loading state; the page polls #status until matches land.
        ensure_processing_enqueued
        @processing = true
      end
    end

    # Lightweight JSON poll target for the loading page. Kept separate from #show
    # (and separately throttled) so polling never trips the results throttle or
    # re-runs the pipeline.
    def status
      render json: {status: current_status}
    end

    private

    def quiz_completed?
      session[:smart_match_user_type].present? && session[:smart_match_causes].present?
    end

    def current_status
      return "unavailable" unless quiz_completed?
      return "ready" if submission_present?
      return "unavailable" if processing_error?

      "processing"
    end

    # Side-effect-free existence check for the JSON poll (unlike find_submission,
    # which may redirect on a stale session id).
    def submission_present?
      id = session[:smart_match_submission_id]
      return true if id && QuizSubmission.exists?(id: id)

      QuizSubmission.exists?(session_id: session.id.to_s)
    end

    def matches_for(submission)
      submission.organization_matches
        .includes(organization: [:causes, :main_location, {logo_attachment: :blob}, {cover_photo_attachment: :blob}])
        .order(:rank)
        .limit(3)
    end

    def find_submission
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

      # A prior background run may have persisted the submission without this
      # request having written the id back to the session yet. Reuse it.
      existing = QuizSubmission.where(session_id: session.id.to_s).order(:created_at).last
      session[:smart_match_submission_id] = existing.id if existing
      existing
    end

    def ensure_processing_enqueued
      # unless_exist makes this a no-op when a job is already in flight, so
      # repeated polls / double-clicks enqueue exactly one job per session.
      newly_claimed = Rails.cache.write(
        SmartMatch::ProcessSubmissionJob.processing_key(session.id.to_s),
        true, unless_exist: true, expires_in: SmartMatch::ProcessSubmissionJob::STATE_TTL
      )
      return unless newly_claimed

      SmartMatch::ProcessSubmissionJob.perform_later(
        session_answers: submission_attributes,
        user_type: session[:smart_match_user_type],
        session_id: session.id.to_s,
        user_id: current_user&.id
      )
    end

    def processing_error?
      Rails.cache.exist?(SmartMatch::ProcessSubmissionJob.error_key(session.id.to_s))
    end

    def reset_processing_state
      Rails.cache.delete(SmartMatch::ProcessSubmissionJob.error_key(session.id.to_s))
      Rails.cache.delete(SmartMatch::ProcessSubmissionJob.processing_key(session.id.to_s))
    end

    def submission_attributes
      {
        state: session[:smart_match_state],
        city: session[:smart_match_city],
        location_scope: session[:smart_match_location_scope],
        travel_bucket: session[:smart_match_travel_bucket],
        causes: session[:smart_match_causes],
        prefs: session[:smart_match_prefs],
        language_input: session[:smart_match_language]
      }
    end
  end
end

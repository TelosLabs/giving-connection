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
        # Post-scoring only: the filter narrows what is shown, it never touches
        # the ranking the job already computed. See SmartMatch::ServiceFilter.
        @service_filter = SmartMatch::ServiceFilter.new(
          pool: @submission.organization_matches, requested: params[:services]
        )
        @page = SmartMatch::ResultsPage.call(
          matches: @service_filter.matches, page: params[:page]
        )
        @results = with_card_associations(@page.matches)
        @relaxations = @submission.search_relaxations
        # Summarised over what is on screen, not the whole pool: the panel
        # counts how many of the SHOWN matches meet each criterion, so it is
        # re-rendered inside the same Turbo frame as the cards.
        @criteria = SmartMatch::CriteriaSummary.call(matches: @results)
      elsif processing_error?
        # Terminal failure recorded by the background job. Clear the flags so
        # the "try again" link starts a fresh attempt, then degrade gracefully.
        reset_processing_state
        @embedding_unavailable = true
      else
        # "?page=" can only mean anything once matches exist, so reaching here
        # with one means there is nothing to page through yet. Send it to the
        # unpaged URL instead of enqueuing from this branch: paged requests are
        # throttled at the higher browsing ceiling (60/hr) precisely because
        # they are pure reads, and letting one start the pipeline would put the
        # expensive path behind that ceiling whenever a submission is missing --
        # which is exactly the state a degraded embedding service leaves behind.
        # The filter is dropped along with the page: it refines an existing
        # result set, and the loading page this redirect lands on finishes by
        # sending the user to the unpaged, unfiltered results anyway.
        return redirect_to smart_match_result_path if params[:page].present?

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

      QuizSubmission.exists?(attempt_token: attempt_token)
    end

    # Preloads are applied to the page ResultsPage chose rather than to the
    # whole pool, so a first page of six does not fetch the logos and cover
    # photos of the fifty-four matches behind it.
    def with_card_associations(matches)
      matches.includes(
        organization: [:causes, :main_location, {logo_attachment: :blob}, {cover_photo_attachment: :blob}]
      )
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

      # The background run may have persisted the submission without this
      # request having written the id back to the session yet. Reuse it -- but
      # only if it belongs to THIS attempt. Falling back to the newest
      # submission for the browser session showed a retaking user their
      # previous answers' matches, silently and permanently (the id was then
      # pinned in the session).
      existing = QuizSubmission.find_by(attempt_token: attempt_token)
      session[:smart_match_submission_id] = existing.id if existing
      existing
    end

    # Identifies this run of the quiz. Set when the quiz completes; generated
    # here as a fallback for a session that reached the results page without
    # going through completion, so lookups never key on nil.
    def attempt_token
      session[:smart_match_attempt_token] ||= SecureRandom.uuid
    end

    def ensure_processing_enqueued
      # unless_exist makes this a no-op when a job is already in flight, so
      # repeated polls / double-clicks enqueue exactly one job per session.
      newly_claimed = Rails.cache.write(
        SmartMatch::ProcessSubmissionJob.processing_key(attempt_token),
        true, unless_exist: true, expires_in: SmartMatch::ProcessSubmissionJob::STATE_TTL
      )
      return unless newly_claimed

      SmartMatch::ProcessSubmissionJob.perform_later(
        session_answers: submission_attributes,
        user_type: session[:smart_match_user_type],
        session_id: session.id.to_s,
        attempt_token: attempt_token,
        user_id: current_user&.id
      )
    end

    def processing_error?
      Rails.cache.exist?(SmartMatch::ProcessSubmissionJob.error_key(attempt_token))
    end

    def reset_processing_state
      Rails.cache.delete(SmartMatch::ProcessSubmissionJob.error_key(attempt_token))
      Rails.cache.delete(SmartMatch::ProcessSubmissionJob.processing_key(attempt_token))
    end

    def submission_attributes
      SmartMatch::QuizNavigator.session_answers(session)
    end
  end
end

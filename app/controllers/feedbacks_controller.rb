# frozen_string_literal: true

class FeedbacksController < ApplicationController
  skip_after_action :verify_authorized
  skip_before_action :authenticate_user!

  SUCCESS_MESSAGE = "Your feedback has been successfully sent! Feel free to send more feedback anytime."
  ERROR_MESSAGE = "Sorry, we couldn't save your feedback. Please try again."

  HONEYPOT_FIELD = :website

  def create
    return respond_with_flash(:notice, SUCCESS_MESSAGE) if honeypot_tripped?

    @feedback = Feedback.new(feedback_params)
    @feedback.user = current_user if user_signed_in?
    @feedback.page_url = same_origin_url(@feedback.page_url.presence || request.referer)

    if @feedback.save
      notify_admin(@feedback)
      respond_with_flash(:notice, SUCCESS_MESSAGE)
    else
      respond_with_flash(:alert, ERROR_MESSAGE, status: :unprocessable_entity)
    end
  end

  private

  def honeypot_tripped?
    params.dig(:feedback, HONEYPOT_FIELD).present?
  end

  def same_origin_url(url)
    return if url.blank?

    parsed = URI.parse(url)
    url if parsed.is_a?(URI::HTTP) && parsed.host == request.host
  rescue URI::InvalidURIError
    nil
  end

  # The feedback is already saved at this point, so a mail/queue hiccup must not
  # turn a successful submission into an error for the visitor. It is reported
  # and swallowed instead.
  def notify_admin(feedback)
    FeedbackMailer.admin_notification(feedback).deliver_later
  rescue => e
    Rollbar.error(e, feedback_id: feedback.id)
  end

  def respond_with_flash(type, message, status: :ok)
    respond_to do |format|
      format.turbo_stream do
        flash.now[type] = message
        render turbo_stream: turbo_stream.update("flash-messages", partial: "shared/flash_messages"),
          status: status
      end
      format.html { redirect_back fallback_location: root_path, flash: {type => message} }
    end
  end

  def feedback_params
    params.require(:feedback).permit(:rating, :category, :comment, :context, :page_url)
  end
end

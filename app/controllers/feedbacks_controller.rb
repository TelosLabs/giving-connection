# frozen_string_literal: true

class FeedbacksController < ApplicationController
  skip_after_action :verify_authorized
  skip_before_action :authenticate_user!

  # UI-only stub for now: accepts the submission and acknowledges it.
  # TODO: persist feedback (rating, category, comment, context) once the
  # data model is defined.
  SUCCESS_MESSAGE = "Your feedback has been successfully sent! Feel free to send more feedback anytime."

  def create
    Rails.logger.info("[Feedback] #{feedback_params.to_h}")

    respond_to do |format|
      format.turbo_stream do
        flash.now[:notice] = SUCCESS_MESSAGE
        render turbo_stream: turbo_stream.update("flash-messages", partial: "shared/flash_messages")
      end
      format.html { redirect_back fallback_location: root_path, notice: SUCCESS_MESSAGE }
    end
  end

  private

  def feedback_params
    params.require(:feedback).permit(:rating, :category, :comment, :context)
  end
end

# frozen_string_literal: true

class FeedbacksController < ApplicationController
  skip_after_action :verify_authorized
  skip_before_action :authenticate_user!

  SUCCESS_MESSAGE = "Your feedback has been successfully sent! Feel free to send more feedback anytime."
  ERROR_MESSAGE = "Sorry, we couldn't save your feedback. Please try again."

  def create
    @feedback = Feedback.new(feedback_params)
    @feedback.user = current_user if user_signed_in?
    @feedback.page_url = @feedback.page_url.presence || request.referer

    if @feedback.save
      respond_with_flash(:notice, SUCCESS_MESSAGE)
    else
      respond_with_flash(:alert, ERROR_MESSAGE, status: :unprocessable_entity)
    end
  end

  private

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

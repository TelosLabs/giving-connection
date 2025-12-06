# frozen_string_literal: true

class NonprofitRequestsController < ApplicationController
  skip_after_action :verify_authorized
  skip_before_action :authenticate_user!
  invisible_captcha only: [:create]

  def new
    @message = Message.new
  end

  def create
    @message = build_message
    if verify_recaptcha(model: @message) && @message.save
      handle_newsletter_subscription if params[:subscribe_to_newsletter] == "1"

      flash[:notice] = "Your message was successfully sent!"
      redirect_to root_path
    else
      flash.now[:error] = "Something went wrong"
      render :new, status: :unprocessable_entity
    end
  end

  private

  def build_message
    DeliveringMessage.new(
      Message.new(message_params)
    )
  end

  def message_params
    params.require(:message).permit(
      :name, :email, :phone, :subject, :organization_name,
      :organization_website, :organization_ein, :profile_admin_name,
      :profile_admin_email, :content
    )
  end

  def handle_newsletter_subscription
    email = params.dig(:message, :email)&.downcase&.strip
    return if email.blank?

    newsletter = Newsletter.find_or_initialize_by(email: email)

    if newsletter.new_record?
      newsletter.save
      NewsletterMailer.verification_email(newsletter).deliver_later
    elsif !newsletter.verified?
      NewsletterMailer.verification_email(newsletter).deliver_later
    end
  end
end

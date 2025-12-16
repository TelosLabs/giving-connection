class NewslettersController < ApplicationController
  skip_before_action :authenticate_user!, only: [:create, :verify]
  skip_after_action :verify_authorized, only: [:create, :verify]
  skip_after_action :verify_policy_scoped, only: [:create, :verify]

  def create
    @newsletter = Newsletter.new(email: params[:email].downcase.strip)

    if verify_recaptcha(model: @newsletter) && @newsletter.save
      NewsletterMailer.verification_email(@newsletter).deliver_later
      flash[:notice] = "Please check your email to confirm your newsletter subscription."
    else
      flash[:alert] = @newsletter.errors.full_messages.join(", ") || "Please complete the reCAPTCHA verification."
    end

    redirect_back(fallback_location: root_path)
  rescue ActiveRecord::RecordNotUnique
    flash[:alert] = "This email is already subscribed to the newsletter."
    redirect_back(fallback_location: root_path)
  end

  def verify
    @newsletter = Newsletter.find_by(verification_token: params[:token])

    if @newsletter&.verify!
      flash[:notice] = "Your newsletter subscription has been confirmed! Thank you for subscribing to the newsletter."
    else
      flash[:alert] = "Invalid or expired verification link."
    end

    redirect_to root_path
  end
end

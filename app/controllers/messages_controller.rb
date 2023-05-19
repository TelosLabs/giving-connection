# frozen_string_literal: true

class MessagesController < ApplicationController
  skip_after_action :verify_authorized
  skip_before_action :authenticate_user!
  invisible_captcha only: [:create], honeypot: :street

  def new
    @message = Message.new
  end

  def create
    @message = build_message
    if verify_recaptcha(model: @message) && @message.save
      flash[:notice] = 'Your message was successfully sent!'
      redirect_to root_path
    else
      flash.now[:error] = 'Something went wrong'
      @form_to_render = message_params[:form_definition]
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
      :profile_admin_email, :content, :form_definition
    )
  end
end

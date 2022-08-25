# frozen_string_literal: true

class MessagesController < ApplicationController
  skip_after_action :verify_authorized
  skip_before_action :authenticate_user!

  def new
    @message = Message.new
  end

  def create
    @message = build_message
    if verify_recaptcha(model: @message) && @message.save
      flash[:notice] = 'Your message was successfully sent!'
      redirect_to root_path
    else
      render :new
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
      :organization_website, :organization_ein, :content
    )
  end
end

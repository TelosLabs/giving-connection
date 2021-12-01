# frozen_string_literal: true

class MessagesController < ApplicationController
  skip_before_action :authenticate_user!
  skip_after_action :verify_authorized

  def new
    @message = Message.new
  end

  def create
    @message = build_message

    if @message.save
      redirect_to root_path
    else
      render :new
      puts search.errors.full_messages
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

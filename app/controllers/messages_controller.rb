# frozen_string_literal: true

class MessagesController < ApplicationController
  skip_after_action :verify_authorized
  skip_before_action :authenticate_user!

  def new
    @message = Message.new
  end

  def create
    @message = build_message
    if @message.save
      flash[:notice] = 'Your message was successfully sent!'
      redirect_to root_path
    else
      render :new
      puts search.errors.full_messages
    end
  end

  private

  def build_message
    # message_params[:subject] = 'I want to publish a nonprofit on Giving Connection' if message_params[:subject] == '1'
    # message_params[:subject] = 'I want to claim ownership of a nonprofit page' if message_params[:subject] == '2'
    # message_params[:subject] = 'Other' if message_params[:subject] == '3'
    # raise
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

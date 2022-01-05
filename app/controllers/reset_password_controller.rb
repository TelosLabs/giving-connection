# frozen_string_literal: true

class ResetPasswordController < ApplicationController
  skip_after_action :verify_authorized

  def new
    current_user.send_reset_password_instructions
    flash[:success] = 'Reset password email sent'
    redirect_to my_account_path
  end
end

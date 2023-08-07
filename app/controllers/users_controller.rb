# frozen_string_literal: true

class UsersController < ApplicationController
  skip_after_action :verify_authorized
  before_action :not_password_change

  def update
    user = current_user

    if not_password_change
      save_params = update_params
    elsif !user.valid_password?(old_password_params[:old_password])
      flash[:alert] = 'Old password is incorrect'
      render 'my_accounts/show'
      return
    else
      save_params = password_params
    end

    flash[:alert] = user.errors.full_messages.to_sentence unless user.update(save_params)
    sign_in(current_user, bypass: true)

    flash_message
    redirect_to my_account_path
  end

  private

  def flash_message
    flash[:sucess] = if email_change
                       I18n.t('devise.confirmations.send_instructions')
                     else
                       'Your information has been updated'
                     end
  end

  def email_change
    update_params[:email].present?
  end

  def not_password_change
    password_params[:password].blank? &&
      password_params[:password_confirmation].blank?
  end

  def update_params
    params.require(:user).permit(:name, :email)
  end

  def password_params
    params.require(:user).permit(:name, :email, :password, :password_confirmation)
  end

  def old_password_params
    params.require(:user).permit(:old_password)
  end
end

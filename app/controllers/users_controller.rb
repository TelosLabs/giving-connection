class UsersController < ApplicationController
  skip_after_action :verify_authorized
  before_action :not_password_change

  def update
    user = current_user

    if not_password_change
      save_params = update_params
    else
      if !user.valid_password?(old_password_params[:old_password])
        flash[:alert] = "Old password is incorrect"
        render 'my_accounts/show'
        return
      else
        save_params = password_params
      end
    end

    unless user.update(save_params)
      flash[:alert] = user.errors.full_messages.to_sentence
      redirect_to my_account_path
    end
  end

  private

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

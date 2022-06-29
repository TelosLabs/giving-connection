class DonatesController < ApplicationController
  skip_before_action :authenticate_user!

  include Pundit

  skip_after_action :verify_policy_scoped
  skip_after_action :verify_authorized

  def show
    @posts = InstagramPost.order(creation_date: :desc)&.last(6)
  end
end
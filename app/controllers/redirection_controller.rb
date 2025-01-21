class RedirectionController < ApplicationController
  skip_before_action :authenticate_user!
  skip_after_action :verify_authorized, only: :notice_external_link

  layout "redirection"

  def notice_external_link
    @target_url = params[:target_url]
  end
end

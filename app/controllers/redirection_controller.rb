class RedirectionController < ApplicationController
  skip_before_action :authenticate_user!
  skip_after_action :verify_authorized, only: :notice_external_link

  layout "redirection"

  def notice_external_link
    @target_url = safe_url(params[:target_url])
  end

  private

  def safe_url(url)
    uri = URI.parse(url)

    uri.to_s if uri.is_a?(URI::HTTP)
  rescue URI::InvalidURIError
    nil
  end
end

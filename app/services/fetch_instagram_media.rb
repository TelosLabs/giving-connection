class FetchInstagramMedia < ApplicationService
  INSTAGRAM_ACCOUNT_ID = Rails.application.credentials.dig(:instagram, :account_id)

  def initialize
    @client = Koala::Facebook::API.new
  end

  def latest_media_posts
    media_endpoint = "#{INSTAGRAM_ACCOUNT_ID}/media?fields=permalink,media_url,media_type,timestamp&limit=50"
    @posts = @client.get_object(media_endpoint)
  end
end

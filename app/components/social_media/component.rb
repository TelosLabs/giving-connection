class SocialMedia::Component < ApplicationViewComponent
  def initialize(social_media:)
    @social_media = social_media
  end
end

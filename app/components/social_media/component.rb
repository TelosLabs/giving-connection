class SocialMedia::Component < ViewComponent::Base
  def initialize(social_media:)
    @social_media = social_media
  end
end

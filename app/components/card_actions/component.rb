class CardActions::Component < ViewComponent::Base
  include ApplicationHelper

  def initialize(current_user:, result:, website:)
    @current_user = current_user
    @result = result
    @website = website
  end

  def website_url
    uri = URI(@result&.decorate&.website || @result&.organization&.decorate&.website)

    if uri.instance_of?(URI::Generic)
      split = uri.to_s.split('/')
      if split.size > 1
        uri = URI::HTTP.build({host: split.shift, path: '/'+split.join('/')})
      else
        uri = URI::HTTP.build({host: split.shift.to_s})
      end
    end
    uri.to_s
  end
end

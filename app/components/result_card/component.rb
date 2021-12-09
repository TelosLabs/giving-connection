# frozen_string_literal: true
class ResultCard::Component < ViewComponent::Base
  def initialize(title:, address:, image_url:, website:, description:, id:, current_user: )
    @title = title
    @address = address
    @image_url = image_url
    @website = website
    @id = id
    @description = description
    @current_user = current_user
  end

  def website_url
    uri = URI(@website)

    if uri.instance_of?(URI::Generic)
      split = uri.to_s.split('/')
      if split.size > 1
        uri = URI::HTTP.build({host: split.shift, path: '/'+split.join('/')})
      else
        uri = URI::HTTP.build({host: uri.to_s})
      end
    end
    uri.to_s
  end
end

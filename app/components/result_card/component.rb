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
      uri = URI::HTTP.build({:host => uri.to_s})
    end
    return uri.to_s
  end
end

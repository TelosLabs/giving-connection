# frozen_string_literal: true
class ResultCard::Component < ViewComponent::Base
  def initialize(title:, address:, image_url:, webpage:, description:, id:, current_user: )
    @title = title
    @address = address
    @image_url = image_url
    @webpage = webpage
    @id = id
    @description = description
    @current_user = current_user
  end
end

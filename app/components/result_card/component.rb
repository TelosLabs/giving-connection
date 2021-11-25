# frozen_string_literal: true
class ResultCard::Component < ViewComponent::Base
  def initialize(title:, address:, image_url:, webpage:, description:, id:)
    @title = title
    @address = address
    @image_url = image_url
    @webpage = webpage
    @id = id
    @description = description
  end
end

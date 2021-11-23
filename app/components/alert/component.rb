# frozen_string_literal: true

class Alert::Component < ViewComponent::Base
  def initialize(key:, message:)
    @key = key
    @message = message
  end
end
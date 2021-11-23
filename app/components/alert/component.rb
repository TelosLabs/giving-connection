# frozen_string_literal: true

# rubocop:disable Style/ClassAndModuleChildren
# rubocop:disable Lint/MissingSuper

# View Component to display flash alerts
class Alert::Component < ViewComponent::Base
  def initialize(key:, message:)
    @key = key
    @message = message
  end

  def background
    return 'bg-green-50' if @key == 'notice'
    return 'bg-red-50' if @key == 'alert'
  end

  def notification_icon
    return 'notice-icon.svg' if @key == 'notice'
    return 'alert-icon.svg' if @key == 'alert'
  end

  def notification_icon_classes
    return 'text-green-400' if @key == 'notice'
    return 'text-red-400' if @key == 'alert'
  end

  def notification_text_classes
    return 'text-green-800' if @key == 'notice'
    return 'text-red-800' if @key == 'alert'
  end

  def button_classes
    return 'bg-green-50 text-green-500 hover:bg-green-100 focus:ring-offset-green-50 focus:ring-green-600' if @key == 'notice'
    return 'bg-red-50 text-red-500 hover:bg-red-100 focus:ring-offset-red-50 focus:ring-red-600' if @key == 'alert'
  end
end

# rubocop:enable Style/ClassAndModuleChildren
# rubocop:enable Lint/MissingSuper

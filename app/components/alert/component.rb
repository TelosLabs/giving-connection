# frozen_string_literal: true

# rubocop:disable Style/ClassAndModuleChildren
# rubocop:disable Lint/MissingSuper

# View Component to display flash alerts
class Alert::Component < ViewComponent::Base
  def initialize(type:, message:)
    @type = type
    @message = message
  end

  def notification
    case @type
    when 'notice'
      {
        background: 'bg-green-50',
        icon: 'notice-icon.svg',
        icon_classes: 'text-green-400',
        text_classes: 'text-green-800',
        button_classes: 'bg-green-50 text-green-500 hover:bg-green-100 focus:ring-offset-green-50 focus:ring-green-600'
      }
    when 'alert', 'error'
      {
        background: 'bg-red-50',
        icon: 'alert-icon.svg',
        icon_classes: 'text-red-400',
        text_classes: 'text-red-800',
        button_classes: 'bg-red-50 text-red-500 hover:bg-red-100 focus:ring-offset-red-50 focus:ring-red-600'
      }
    else
      {
        background: 'bg-blue-50',
        icon: 'notice-icon.svg',
        icon_classes: 'text-blue-400',
        text_classes: 'text-blue-800',
        button_classes: 'bg-blue-50 text-blue-500 hover:bg-blue-100 focus:ring-offset-blue-50 focus:ring-blue-600'
      }
    end
  end
end

# rubocop:enable Style/ClassAndModuleChildren
# rubocop:enable Lint/MissingSuper

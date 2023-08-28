class AlertDecorator < ApplicationDecorator
  delegate_all

  def title(index)
    return "Alert #{index + 1}" unless object.keyword.present?

    object.keyword
  end
end

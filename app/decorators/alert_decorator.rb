class AlertDecorator < ApplicationDecorator
  delegate_all

  def title(index)
    object.keyword.presence || "Alert #{index + 1}"
  end
end

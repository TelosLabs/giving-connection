class AlertDecorator < ApplicationDecorator
  delegate_all

  def title(index)
    if object.keyword.present?
      "Keyword: #{object.keyword}"
    else
      "Alert #{index + 1}"
    end
  end
end

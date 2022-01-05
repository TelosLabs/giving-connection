# frozen_string_literal: true

class ApplicationDecorator < Draper::Decorator
  # Define methods for all decorated objects.
  # Helpers are accessed through `helpers` (aka `h`). For example:
  #
  #   def percent_amount
  #     h.number_to_percentage object.amount, precision: 2
  #   end

  def website
    return nil if object.website.blank?

    uri = URI(object.website)
    if uri.instance_of?(URI::Generic)
      split = uri.to_s.split('/')
      uri = if split.size > 1
              URI::HTTP.build({ host: split.shift, path: "/#{split.join('/')}" })
            else
              URI::HTTP.build({ host: split.shift.to_s })
            end
    end
    uri.to_s
  end
end

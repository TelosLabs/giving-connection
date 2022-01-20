# frozen_string_literal: true

require 'administrate/field/base'

class HiddenField < Administrate::Field::Base
  def to_s
    data
  end

  def stimulus_controller
    case attribute
    when :latitude
      'places'
    when :longitude
      'places'
    end
  end

  def stimulus_target
    case attribute
    when :latitude
      attribute.to_s
    when :longitude
      attribute.to_s
    end
  end
end

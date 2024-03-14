# frozen_string_literal: true

require "administrate/field/base"

class TimeSelectField < Administrate::Field::Base
  def to_s
    data
  end
end

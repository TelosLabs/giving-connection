# frozen_string_literal: true
require "administrate/field/base"

class MultiSelectField < Administrate::Field::Base
  def to_s
    Array(data).join(", ")
  end

  def collection
    options.fetch(:collection, [])
  end

  alias_method :choices, :collection
end

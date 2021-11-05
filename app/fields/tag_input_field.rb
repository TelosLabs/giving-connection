require "administrate/field/base"

class TagInputField < Administrate::Field::Base
  def to_s
    data
  end
end

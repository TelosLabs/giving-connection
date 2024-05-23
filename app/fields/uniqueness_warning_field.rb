require "administrate/field/base"

class UniquenessWarningField < Administrate::Field::Base
  def to_s
    data
  end
end

require "administrate/field/base"

class CheckboxField < Administrate::Field::Base
  def to_s
    data
  end

  def beneficiary_types
    Beneficiary.all
  end
end

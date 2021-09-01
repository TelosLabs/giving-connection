class Testing < ApplicationRecord
  attr_accessor  :name

  def get_name
    return  self.name
  end
end

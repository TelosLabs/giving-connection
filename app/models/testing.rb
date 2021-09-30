class Testing < ApplicationRecord
  attr_accessor :name

  def get_name
    name + "asdf"
  end
end

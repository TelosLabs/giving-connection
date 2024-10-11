# frozen_string_literal: true

class Testing < ApplicationRecord
  attr_accessor :name

  def get_name
    name
  end
end

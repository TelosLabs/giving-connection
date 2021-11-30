# frozen_string_literal: true

class ApplicationQuery
  def self.call(*params)
    new(*params).call
  end
end

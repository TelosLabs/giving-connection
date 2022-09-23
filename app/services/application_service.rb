require 'dry-initializer'

class ApplicationService
  extend Dry::Initializer
  def self.call(...)
    new(...).call
  end
end

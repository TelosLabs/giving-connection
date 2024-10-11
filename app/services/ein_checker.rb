class EinChecker < ApplicationService
  def initialize(ein)
    @ein = ein
  end

  def call
    exists = Organization.find_by(ein_number: @ein).present?
    {exists: exists}
  end
end

class CausesController < ApplicationRecord
  def index
    @location_causes = LocationCause.all
  end
end

# frozen_string_literal: true

# navbar view component
class NavbarComponent < ViewComponent::Base
  def initialize(signed_in:)
    @signed_in = signed_in
  end
end

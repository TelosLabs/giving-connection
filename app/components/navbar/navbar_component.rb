# frozen_string_literal: true

# navbar view component
class Navbar::NavbarComponent < ViewComponent::Base
  def initialize(signed_in:)
    @signed_in = signed_in
  end
end

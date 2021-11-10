# frozen_string_literal: true

# sidebar view component
class SideNavbarComponent < ViewComponent::Base
  def initialize(signed_in:)
    super
    @signed_in = signed_in
  end
end

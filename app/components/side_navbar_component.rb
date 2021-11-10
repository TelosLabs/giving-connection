class SideNavbarComponent < ViewComponent::Base
  def initialize(signed_in:)
    @signed_in = signed_in
  end
end

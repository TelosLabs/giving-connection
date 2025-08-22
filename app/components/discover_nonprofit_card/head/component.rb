class DiscoverNonprofitCard::Head::Component < ApplicationViewComponent
  include InlineSvg::ActionView::Helpers

  def initialize(location:)
    @location = location
  end
end

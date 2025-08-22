# frozen_string_literal: true

# Accordion Component for faqs page
class Accordion::Component < ApplicationViewComponent
  include InlineSvg::ActionView::Helpers
  
  def initialize(title:, description:)
    @title = title
    @description = description
  end
end

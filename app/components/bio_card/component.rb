# frozen_string_literal: true

class BioCard::Component < ApplicationViewComponent
  include InlineSvg::ActionView::Helpers
  renders_one :biography

  def initialize(name: "", job_title: "", img_url: "")
    @name = name
    @job_title = job_title
    @img_url = img_url
  end
end

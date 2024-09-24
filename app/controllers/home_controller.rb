# frozen_string_literal: true

class HomeController < ApplicationController
  skip_after_action :verify_policy_scoped
  skip_before_action :authenticate_user!

  FIRST_VISIT_TEXT = "Connect with a nonprofit today."
  RETURN_VISIT_TEXTS = [
    "Connect with a nonprofit today.",
    "Find your local nonprofit today.",
    "Discover good in your neighborhood.",
    "Your North Star for service."
  ].freeze

  def index
    @search = Search.new
    @main_text = dynamic_main_text
  end

  private

  def dynamic_main_text
    if session[:has_visited_before]
      RETURN_VISIT_TEXTS.sample
    else
      session[:has_visited_before] = true
      FIRST_VISIT_TEXT
    end
  end
end

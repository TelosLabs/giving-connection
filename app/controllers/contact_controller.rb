# frozen_string_literal: true

# controller added for contact form
class ContactController < ApplicationController
  skip_before_action :authenticate_user!

  def index; end
end

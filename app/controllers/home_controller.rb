# frozen_string_literal: true
require 'maxmind/db'
require 'locations_helper'


class HomeController < ApplicationController
  skip_after_action :verify_policy_scoped
  skip_before_action :authenticate_user!
  include LocationsHelper

  def index
    @search = Search.new
    puts get_ip_location
    @location = get_ip_location
  end

end

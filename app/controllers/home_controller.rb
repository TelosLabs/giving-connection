# frozen_string_literal: true
require 'maxmind/db'


class HomeController < ApplicationController
  skip_after_action :verify_policy_scoped
  skip_before_action :authenticate_user!

  def index
    @search = Search.new
    get_ip_location
  end

  private
  def get_ip_location
    reader = MaxMind::DB.new("#{Rails.root}/app/assets/GeoLite2-City.mmdb", mode: MaxMind::DB::MODE_MEMORY)

    record = reader.get('162.231.222.138')
    if record.nil?
      puts request.remote_ip.to_s
      puts '1.1.1.1 was not found in the database'
    else
      puts record.to_hash
      @location = [
        {
          city: record.to_hash['city']['names']['en'],
          state: record.to_hash['subdivisions'][0]['iso_code'],
          latitude: record.to_hash['location']['latitude'],
          longitude: record.to_hash['location']['longitude']
        }
      ]

      # puts record['country']['iso_code']
      # puts record['country']['names']['en']
    end

    reader.close
  end
end

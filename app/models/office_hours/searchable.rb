# frozen_string_literal: true

module OfficeHours
  module Searchable
    extend ActiveSupport::Concern

    def open_now?(check_time)
      closed? || check_time > close_time.to_time
    end

  end
end

# frozen_string_literal: true

class OfficeHoursValidator < ActiveModel::Validator
  attr_reader :record

  def validate(record)
    @record = record
    close_hour_after_open_hour
  end

  private

  def close_hour_after_open_hour
    # return true if record.closed?

    # if record&.open_time >= record&.close_time
    #   record.location.organization.errors.add(:base, 'Closing time must be after opening time')
    # end
  end
end

# >> params['organization']['locations_attributes']["0"]["office_hours_attributes"]
# <ActionController::Parameters
# {"0"=>{"day"=>"0", "open_time"=>"06:00", "close_time"=>"18:00", "closed"=>"0"},
# "1"=>{"day"=>"1", "open_time"=>"05:58", "close_time"=>"18:00", "closed"=>"0"},
# "2"=>{"day"=>"2", "open_time"=>"06:00", "close_time"=>"17:00", "closed"=>"0"},
# "3"=>{"day"=>"3", "open_time"=>"06:00", "close_time"=>"18:00", "closed"=>"0"},
# "4"=>{"day"=>"4", "open_time"=>"06:00", "close_time"=>"17:00", "closed"=>"0"},
# "5"=>{"day"=>"5", "open_time"=>"", "close_time"=>"", "closed"=>"1"},
# "6"=>{"day"=>"6", "open_time"=>"", "close_time"=>"", "closed"=>"1"}} permitted: false>

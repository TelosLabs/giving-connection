class OfficeHoursValidator < ActiveModel::Validator
  attr_reader :record

  def validate(record)
    @record = record
    exactly_seven_records
  end

  private

  def exactly_seven_records
    record.office_hours.length == 7 &&
    Date::DAYNAMES.all? do |day|
      record.office_hours.pluck(:day).include?(day)
    end
  end

end

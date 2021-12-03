class LocationValidator < ActiveModel::Validator
  attr_reader :record

  def validate(record)
    @record = record
    complete_office_hours
  end

  private

  def complete_office_hours
    return true if record.appointment_only?

    unless Time::DAYS_INTO_WEEK.values.sort == record.office_hours.map(&:day).sort
      record.organization.errors.add(:base, 'Office hours data is required for the 7 days of the week')
    end
  end
end

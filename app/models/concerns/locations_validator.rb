class LocationsValidator < ActiveModel::Validator
  attr_reader :record

  def validate(record)
    @record = record
    single_main_location
    at_least_one_main_location
    complete_office_hours
  end

  private

  def single_main_location
    main_org = record.organization.locations.where(main: true)
    return true if main_org.first == record
    if main_org.size >= 1 && record.main
      record.organization.errors.add(:base, 'Only one main location is required')
    end
  end

  def at_least_one_main_location
    main_org = record.organization.locations.where(main: true)
    return true if main_org.first == record
    if main_org.empty? && !record.main
      record.organization.errors.add(:base, 'At least one main location is required')
    end
  end

  def complete_office_hours
    return true if record.appointment_only?

    unless Time::DAYS_INTO_WEEK.values.sort == record.office_hours.map(&:day).sort
      record.organization.errors.add(:base, 'Office hours data is required for the 7 days of the week')
    end
  end
end

class LocationsValidator < ActiveModel::Validator
  attr_reader :record

  def validate(record)
    @record = record
    single_main_location
    at_least_one_main_location
    exactly_seven_records
  end

  private

  def single_main_location
    main_org = record.organization.locations.where(main: true)
    if main_org.size >= 1 && record.main
      record.organization.errors.add(:base, 'Only one main location is required')
    end
  end

  def at_least_one_main_location
    main_org = record.organization.locations.where(main: true)
    if main_org.empty? && !record.main
      record.organization.errors.add(:base, 'at least one main location is required')
    end
  end

  def exactly_seven_records
    unless Time::DAYS_INTO_WEEK.sort == record.office_hours.pluck(:day).sort
      record.errors.add(:base, 'office hours data is required for the 7 days of the week')
    end
  end
end

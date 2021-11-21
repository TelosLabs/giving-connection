class MainLocationValidator < ActiveModel::Validator
  attr_reader :record

  def validate(record)
    @record = record
    single_main_location
    at_least_one_main_location
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
end

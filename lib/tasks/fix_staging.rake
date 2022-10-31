namespace :fix_staging do
  desc 'Delete duplicate causes and services'
  task delete_duplicate_causes_and_services: :environment do
    unless Rails.env.production?
      delete_duplicate_causes
      delete_remaining_services
      delete_remaining_causes
    end
  end

  private

  def delete_duplicate_causes
    Organizations::Constants::CAUSES_AND_SERVICES.each do |cause, services|
      similar_causes = Cause.where('name LIKE ?', "#{cause}%")

      puts "There are #{similar_causes.count} with name like #{cause}"
      Rails.logger.info "There are #{similar_causes.count} with name like #{cause}"
      next unless similar_causes.count >= 2

      real_cause = find_real_cause(similar_causes, cause, services)

      unless real_cause
        puts "No real cause for #{cause}"
        Rails.logger.info "The real cause for #{cause}"
        next
      end

      puts "The real cause for #{real_cause.name} has the id #{real_cause.id}"
      Rails.logger.info "The real cause for #{real_cause.name} has the id #{real_cause.id}"

      duplicate_causes = similar_causes - [real_cause]
      delete_causes(duplicate_causes, real_cause)
    end
  end

  def find_real_cause(similar_causes, cause, services)
    similar_causes.each do |similar_cause|
      similar_services = similar_cause.services.pluck(:name)
      return similar_cause if similar_cause.name == cause && similar_services == services
    end
  end

  def delete_causes(duplicate_causes, real_cause)
    duplicate_causes.each do |duplicate_cause|
      AlertCause.where(cause_id: duplicate_cause.id).update_all(cause_id: real_cause.id)
      OrganizationCause.where(cause_id: duplicate_cause.id).update_all(cause_id: real_cause.id)
      duplicate_services = Service.where(cause_id: duplicate_cause.id)

      update_services(duplicate_services, real_cause)
      duplicate_cause.services.destroy_all
      duplicate_cause.destroy
    end
  end

  def update_services(duplicate_services, real_cause)
    duplicate_services.each do |duplicate_service|
      real_service = real_cause.services.find_by(name: duplicate_service.name)
      if real_service
        LocationService.where(service_id: duplicate_service.id).update_all(service_id: real_service.id)
        AlertService.where(service_id: duplicate_service.id).update_all(service_id: real_service.id)
      else
        LocationService.where(service_id: duplicate_service.id).destroy_all
        AlertService.where(service_id: duplicate_service.id).destroy_all
      end
    end
  end

  def delete_remaining_services
    real_service_names = Organizations::Constants::CAUSES_AND_SERVICES.values.sum
    real_service_ids = Service.where(name: real_service_names).pluck(:id).uniq
    LocationService.where.not(service_id: real_service_ids).destroy_all
    AlertService.where.not(service_id: real_service_ids).destroy_all
    Service.where.not(id: real_service_ids).destroy_all
  end

  def delete_remaining_causes
    real_cause_names = Organizations::Constants::CAUSES_AND_SERVICES.keys
    real_cause_ids = Cause.where(name: real_cause_names).pluck(:id).uniq
    OrganizationCause.where.not(cause_id: real_cause_ids).destroy_all
    AlertCause.where.not(cause_id: real_cause_ids).destroy_all
    Service.where.not(cause_id: real_cause_ids).destroy_all
    Cause.where.not(id: real_cause_ids).destroy_all
  end
end

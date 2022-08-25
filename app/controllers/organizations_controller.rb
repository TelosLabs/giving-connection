# frozen_string_literal: true

class OrganizationsController < ApplicationController
  def show
    @organization = Organization.active.find(params[:id])
    authorize @organization
  end

  def new
    @organization = Organization.new
  end

  def edit
    @organization = Organization.find(params[:id])
    authorize @organization
    set_form_data
  end

  def update
    @organization = Organization.find(params[:id])
    authorize @organization
    if @organization.update(organization_params)
      update_location_services(params['organization']['locations_attributes']) unless params['organization']['locations_attributes'].empty? || params['organization']['locations_attributes'].nil?
      update_organization_beneficiaries(@organization, params['organization']['beneficiary_subcategories']) unless params['organization']['beneficiary_subcategories'].empty?
      update_organization_causes(@organization, params['organization']['causes']) unless params['organization']['causes'].nil?
      update_tags(@organization, JSON.parse(params['organization']['tags_attributes'])) unless params['organization']['tags_attributes'].strip.empty?
      redirect_to my_account_path
      flash[:notice] = 'The Organization was successfully updated'
    else
      set_form_data
      flash.now[:alert] = 'The Organization was not updated'
      render 'edit', status: :unprocessable_entity
    end
  end

  def set_form_data
    @causes = Cause.order(:name).pluck(:name)
    @beneficiaries = BeneficiarySubcategory.order(:name).pluck(:name)
    @beneficiary_groups = set_beneficiary_groups
    @services = set_services
  end

  def set_services
    @services = {}
    Cause.all.each do |cause|
      @services[cause.name] = cause.services.map(&:name)
    end
    if (@services.is_a?(Hash))
      @services
    end
  end

  def set_beneficiary_groups
    @beneficiary_groups = {}
    BeneficiaryGroup.all.each do |group|
      @beneficiary_groups[group.name] = group.beneficiary_subcategories.map(&:name)
    end
    if (@beneficiary_groups.is_a?(Hash))
      @beneficiary_groups
    end
  end

  def create_tags(organization, tags)
    tags.each do |tag_hash|
      Tag.create!(organization: organization, name: tag_hash['value'])
    end
  end

  def update_tags(organization, tags)
    to_create = tags - organization.tags.map(&:name)
    to_delete = organization.tags.map(&:name) - tags

    create_tags(organization, to_create)
    delete_tags(organization, to_delete)
  end

  def delete_tags(organization, tags)
    tags.each do |tag_name|
      organization.tags.find_by(name: tag_name).delete
    end
  end

  def update_organization_beneficiaries(organization, beneficiary_subcategories)
    organization.beneficiary_subcategories.destroy_all
    beneficiary_subcategories = beneficiary_subcategories.to_unsafe_h.map {|subcategory| subcategory.flatten}.flatten

    beneficiary_subcategories.each do |beneficiary_subcategory_hash|
      beneficiary_subcategory = BeneficiarySubcategory.find_by_name(beneficiary_subcategory_hash)
      OrganizationBeneficiary.create!(organization: organization, beneficiary_subcategory: beneficiary_subcategory) if beneficiary_subcategory
    end
  end

  def update_organization_causes(organization, causes)
    organization.organization_causes.destroy_all
    causes.each do |cause_hash|
      cause = Cause.find_by_name(cause_hash)
      OrganizationCause.create!(organization: organization, cause: cause) if cause
    end
  end

  def update_location_services(locations_attributes)
    locations_attributes.each do |location|
      @location = Location.find_by_name(location.last['name'])
      location_services = location.last['location_services_attributes']['0']['services']['service'].values.flatten

      if @location&.offer_services
        next if location.last['location_services_attributes']['0']['services']['service'].empty? || location.last['location_services_attributes'].nil?
        @location.location_services.destroy_all
        location_services.each do |service|
          LocationService.create(location: @location, service: Service.find_by_name(service))
        end
      end
    end
  end

  def organization_params
    params.require(:organization)
          .permit(:name, :second_name, :ein_number, :irs_ntee_code, :website, :scope_of_work,
                  :mission_statement_en, :mission_statement_es, :vision_statement_en, :logo,
                  :vision_statement_es, :tagline_en, :tagline_es, :email, :phone_number, :active, :verified, :donation_link,
                  social_media_attributes: %i[facebook instagram twitter linkedin youtube blog id],
                  tags_attributes: [],
                  locations_attributes: [:id, :name, :address, :latitude, :longitude, :website, :po_box,
                                         :main, :physical, :offer_services, :appointment_only, :email, :_destroy,
                                         { phone_number_attributes: [:number],
                                           office_hours_attributes: %i[id day open_time close_time closed]
                                         }],
                  beneficiary_subcategories: [],
                  causes: [])
  end
end

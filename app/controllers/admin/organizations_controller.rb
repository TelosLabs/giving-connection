# frozen_string_literal: true

module Admin
  class OrganizationsController < Admin::ApplicationController
    # Overwrite any of the RESTful controller actions to implement custom behavior
    # For example, you may want to send an email after a foo is updated.
    #
    # def update
    #   super
    #   send_foo_updated_email(requested_resource)
    # end

    def upload
    end

    def import
      @creator = current_admin_user
      results = SpreadsheetParse.new(params[:file], @creator).import
      flash.now[:notice] = log_results(results)
      render :upload, status: :unprocessable_entity
    end

    def new
      resource = new_resource
      authorize_resource(resource)
      resource.build_social_media
      # loc = resource.build_main_location
      # Time::DAYS_INTO_WEEK.each do |k,v|
      #   loc.office_hours.build(day: v, open_time: "10:00", close_time: "16:00")
      # end
      render locals: {
        page: Administrate::Page::Form.new(dashboard, resource)
      }
    end

    def create
      organization_resource_params = resource_params.except("beneficiary_subcategories_id") # .except('services_id')
      resource = resource_class.new(organization_resource_params)
      resource.creator = current_admin_user
      authorize_resource(resource)
      if resource.save
        create_organization_beneficiaries(resource, resource_params["beneficiary_subcategories_id"]) unless resource_params["beneficiary_subcategories_id"].nil?
        create_tags(resource, JSON.parse(params["tags_attributes"])) unless params["tags_attributes"].strip.empty?
        redirect_to([namespace, resource], notice: translate_with_resource("create.success"))
      else
        render :new, locals: {page: Administrate::Page::Form.new(dashboard, resource)}, status: :unprocessable_entity
      end
    end

    def update
      organization_resource_params = resource_params.except("beneficiary_subcategories_id")
      requested_resource.creator = current_admin_user
      if requested_resource.update(organization_resource_params)
        requested_resource.update!(beneficiary_subcategory_ids: resource_params["beneficiary_subcategories_id"])
        update_tags(requested_resource, JSON.parse(params["tags_attributes"])) unless params["tags_attributes"].strip.empty?
        redirect_to([namespace, requested_resource], notice: translate_with_resource("update.success"))
      else
        render :edit, locals: {page: Administrate::Page::Form.new(dashboard, requested_resource)},
          status: :unprocessable_entity
      end
    end

    def create_organization_beneficiaries(organization, beneficiaries_sub_ids)
      beneficiaries_sub_ids.each do |beneficiary_sub_id|
        beneficiary_subcategory = BeneficiarySubcategory.find(beneficiary_sub_id)
        OrganizationBeneficiary.create!(organization: organization, beneficiary_subcategory: beneficiary_subcategory)
      end
    end

    def create_tags(organization, tags)
      tags.each do |tag_hash|
        Tag.create!(organization: organization, name: tag_hash["value"])
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

    def resource_params
      permit = dashboard.permitted_attributes << {social_media_attributes: %i[facebook instagram twitter linkedin youtube blog id],
                                                   service_attributes: %i[name description id],
                                                   beneficiary_subcategories_id: [],
                                                   services_id: [],
                                                   location_attributes: %i[address latitude longitude website main offer_services non_standard_office_hours],
                                                   tags_attributes: [],
                                                   office_hours_attributes: %i[day open_time close_time closed]}
      params.require(resource_class.model_name.param_key)
        .permit(permit)
        .transform_values { |value| (value == "") ? nil : value }
    end

    def check_ein
      render json: EinChecker.new(params[:ein_number]).call
    end

    private

    def log_results(results)
      "#{results[:ids].size} organizations succesfully created. <br>" \
      "#{results[:failed_instances].size} organizations failed: <br>"
    end
  end
end

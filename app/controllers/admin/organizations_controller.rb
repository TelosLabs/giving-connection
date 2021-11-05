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

    def new
      resource = new_resource
      authorize_resource(resource)
      resource.build_social_media
      resource.build_main_location
      render locals: {
        page: Administrate::Page::Form.new(dashboard, resource)
      }
    end

    def create
      organization_resource_params = resource_params.except('beneficiary_subcategories_id')
      resource = resource_class.new(organization_resource_params)
      resource.creator = current_admin_user
      authorize_resource(resource)
      if resource.save
        create_organization_beneficiaries(resource, resource_params['beneficiary_subcategories_id']) unless resource_params['beneficiary_subcategories_id'].nil?
        create_tags(resource, JSON.parse(params["tags_attributes"])) unless params["tags_attributes"].nil?
        redirect_to([namespace, resource], notice: translate_with_resource('create.success'))
      else
        render :new, locals: { page: Administrate::Page::Form.new(dashboard, resource) }, status: :unprocessable_entity
      end
    end

    def update
      organization_resource_params = resource_params.except('beneficiary_subcategories_id')
      requested_resource.creator = current_admin_user
      requested_resource.update(organization_resource_params)
      if requested_resource
        update_organization_beneficiaries(requested_resource, resource_params['beneficiary_subcategories_id']) unless resource_params['beneficiary_subcategories_id'].nil?
        update_tags(requested_resource, JSON.parse(params["tags_attributes"])) unless params["tags_attributes"].nil?
        redirect_to([namespace, requested_resource], notice: translate_with_resource('update.success'))
      else
        render :edit, locals: { page: Administrate::Page::Form.new(dashboard, requested_resource) },
                      status: :unprocessable_entity
      end
    end

    def create_organization_beneficiaries(organization, beneficiaries_sub_ids)
      beneficiaries_sub_ids.each do |beneficiary_sub_id|
        beneficiary_subcategory = BeneficiarySubcategory.find(beneficiary_sub_id)
        OrganizationBeneficiary.create!(organization: organization, beneficiary_subcategory: beneficiary_subcategory)
      end
    end

    def update_organization_beneficiaries(organization, beneficiaries_sub_ids)
      to_create = beneficiaries_sub_ids - organization.beneficiary_subcategories.ids
      to_delete = organization.beneficiary_subcategories.ids - beneficiaries_sub_ids

      create_organization_beneficiaries(organization, to_create)
      delete_organization_beneficiaries(organization, to_delete)
    end

    def delete_organization_beneficiaries(organization, beneficiaries_sub_ids)
      beneficiaries_sub_ids.each do |beneficiary_sub_id|
        organization.organization_beneficiaries.find_by(beneficiary_subcategory_id: beneficiary_sub_id).delete
      end
    end

    def create_tags(organization, tags)
      tags.each do |tag_hash|
        Tag.create!(organization: organization, name: tag_hash['value'])
      end
    end

    def update_tags(organization, tags)
      to_create = tags - organization.tags.map { |tag| tag.name }
      to_delete = organization.tags.map { |tag| tag.name } - tags  
      
      create_tags(organization, to_create)
      delete_tags(organization, to_delete)
    end

    def delete_tags(organization, tags)
      tags.each do |tag_name|
        organization.tags.find_by(name: tag_name).delete
      end
    end

    def resource_params
      permit = dashboard.permitted_attributes << { social_media_attributes: %i[facebook instagram twitter linkedin
                                                                               youtube blog id],
                                                   service_attributes: %i[name description id],
                                                   beneficiary_subcategories_id: [],
                                                   main_location_attributes: %i[address latitude longitude website main physical offer_services],
                                                   tags_attributes: []}
      params.require(resource_class.model_name.param_key)
            .permit(permit)
            .transform_values { |value| value == '' ? nil : value }
    end

    # See https://administrate-prototype.herokuapp.com/customizing_controller_actions
    # for more information
  end
end

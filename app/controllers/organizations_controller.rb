# frozen_string_literal: true

class OrganizationsController < ApplicationController
  def show
    @organization = Organization.find(params[:id])
    authorize @organization
  end

  def edit
    @organization = Organization.find(params[:id])
    @location = @organization.locations.first
    authorize @organization
  end

  def update
    @organization = Organization.find(params[:id])
    authorize @organization
    raise
    if @organization.update(organization_params)
      # update_organization_beneficiaries(requested_resource, resource_params['beneficiary_subcategories_id']) unless resource_params['beneficiary_subcategories_id'].nil?
      update_tags(@organization, JSON.parse(params['tags_attributes'])) unless params['tags_attributes'].strip.empty?
      redirect_to organization_path(@organization)
    else
      render :edit
    end
  end

  def organization_params
    params.require(:organization)
          .permit(:name, :ein_number, :irs_ntee_code, :website, :scope_of_work,
                  :mission_statement_en, :mission_statement_es, :vision_statement_en,
                  :vision_statement_es, :tagline_en, :tagline_es, :email, :phone_number,
                  social_media_attributes: %i[facebook instagram twitter linkedin youtube blog id],            
                  tags_attributes: [],
                  locations_attributes: %i[address latitude longitude website main physical offer_services appointment_only])
    # service_attributes: %i[name description id],
    # beneficiary_subcategories_id: [],
    # services_id: [],
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
end

 # JSON.parse(params['tags_attributes'])
 # [{"value"=>"tagssssssss"}, {"value"=>"botafogoo"}]
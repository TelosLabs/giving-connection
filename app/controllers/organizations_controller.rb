# frozen_string_literal: true

class OrganizationsController < ApplicationController
  def show
    @organization = Organization.find(params[:id])
    authorize @organization
  end

  def edit
    @organization = Organization.find(params[:id])
    authorize @organization
  end

  def update
    @organization = Organization.find(params[:id])
    @organization.update(organization_params)
    authorize @organization

    redirect_to organization_path(@organization)
  end


  def organization_params
    params.require(:organization)
          .permit(:name, :ein_number, :irs_ntee_code, :website, :scope_of_work,
                  :mission_statement_en, :mission_statement_es, :vision_statement_en,
                  :vision_statement_es, :tagline_en, :tagline_es)
                  # ,social_media_attributes: %i[facebook instagram twitter linkedin youtube blog id],
                  # service_attributes: %i[name description id],
                  # beneficiary_subcategories_id: [],
                  # services_id: [],
                  # main_location_attributes: %i[address latitude longitude website main physical offer_services],
                  # tags_attributes: [])
  end
end

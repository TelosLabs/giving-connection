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
    @form_presenter = OrganizationFormPresenter.new

    authorize @organization
    set_form_data
  end

  def update
    @organization = Organization.find(params[:id])
    authorize @organization
    if @organization.update(organization_params)
      update_tags(@organization, JSON.parse(params["organization"]["tags_attributes"])) unless params["organization"]["tags_attributes"].strip.empty?

      # Handle AJAX requests differently
      if request.xhr?
        render json: {success: true, message: "The Organization was successfully updated"}
      else
        redirect_to my_account_path
        flash[:notice] = "The Organization was successfully updated"
      end
    else
      set_form_data
      if request.xhr?
        render json: {success: false, errors: @organization.errors.full_messages}, status: :unprocessable_entity
      else
        flash.now[:alert] = "The Organization was not updated"
        render "edit", status: :unprocessable_entity
      end
    end
  end

  def delete_upload
    @organization = Organization.find(params[:id])
    authorize @organization
    @attachment = ActiveStorage::Attachment.find(params[:upload_id])
    @attachment.purge
    redirect_to edit_organization_path(@organization, anchor: "location-specific-fields")
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
    if @services.is_a?(Hash)
      @services
    end
  end

  def set_beneficiary_groups
    @beneficiary_groups = {}
    BeneficiaryGroup.all.each do |group|
      @beneficiary_groups[group.name] = group.beneficiary_subcategories.map(&:name)
    end
    if @beneficiary_groups.is_a?(Hash)
      @beneficiary_groups
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

  def check_ein
    render json: EinChecker.new(params[:ein_number]).call
    skip_authorization
  end

  def organization_params
    params.require(:organization).permit(
      :name,
      :second_name,
      :ein_number,
      :irs_ntee_code,
      :website,
      :scope_of_work,
      :mission_statement_en,
      :mission_statement_es,
      :vision_statement_en,
      :logo,
      :vision_statement_es,
      :tagline_en,
      :tagline_es,
      :email,
      :phone_number,
      :active,
      :verified,
      :donation_link,
      :volunteer_availability,
      :volunteer_link,
      :general_population_serving,
      social_media_attributes: %i[facebook instagram twitter linkedin youtube blog id],
      tags_attributes: [],
      locations_attributes: [
        :id,
        :name,
        :address,
        :latitude,
        :longitude,
        :website,
        :po_box,
        :public_address,
        :youtube_video_link,
        :main,
        :offer_services,
        :time_zone,
        :non_standard_office_hours,
        :email,
        :_destroy,
        {
          phone_number_attributes: [:number],
          office_hours_attributes: %i[id day open_time close_time closed],
          images: [],
          service_ids: []
        }
      ],
      beneficiary_subcategory_ids: [],
      cause_ids: []
    )
  end
end

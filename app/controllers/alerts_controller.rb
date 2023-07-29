# frozen_string_literal: true

class AlertsController < ApplicationController
  include Pundit

  def new
    @alert = Alert.new
    @alert_params = params['alert_params']
    authorize @alert
  end

  def create
    new_alert = Alert.new(alert_params)
    new_alert.user = current_user
    new_alert = clean_open_weekends(new_alert)
    if new_alert.save
      create_alert_services(new_alert, params['search']['services']) unless params['search']['services'].nil?
      create_alert_beneficiaries(new_alert, params['search']['beneficiary_groups']) unless params['search']['beneficiary_groups'].nil?
      create_alert_causes(new_alert, params['search']['causes']) unless params['search']['causes'].nil?
      render json: { data: 'OK', status: 200 }
    end
    update_alert_search_results(new_alert)
    authorize new_alert
  end

  def edit
    @alert = Alert.find(params[:id])
    authorize @alert
  end

  def update
    @alert = Alert.find(params[:id])
    @alert.update(alert_params)
    authorize @alert
  end

  def destroy
    @alert = Alert.find(params[:id])
    @alert.destroy
    authorize @alert
    flash[:success] = "The alert was successfully deleted."
    redirect_to my_account_path
  end

  private

  def alert_params
    params.require(:search).permit(:distance, :city, :state, :open_weekends, :keyword, :frequency, :causes, :services, :beneficiary_groups)
  end

  def clean_open_weekends(new_alert)
    new_alert.update!(open_weekends: false) unless new_alert.open_weekends == true
    new_alert
  end

  def create_alert_causes(alert, causes)
    causes.each do |cause|
      find_cause = Cause.find_by_name(cause)
      AlertCause.create!(cause: find_cause, alert: alert)
    end
  end

  def create_alert_services(alert, services)
    services.values.flatten.each do |service|
      find_service = Service.find_by_name(service)
      AlertService.create!(service: find_service, alert: alert)
    end
  end

  def create_alert_beneficiaries(alert, beneficiaries_and_subcategories)
    beneficiaries_and_subcategories.values.flatten.each do |beneficiary|
      find_beneficiary = BeneficiarySubcategory.find_by_name(beneficiary)
      AlertBeneficiary.create!(beneficiary_subcategory: find_beneficiary, alert: alert)
    end
  end

  def update_alert_search_results(alert)
    search_results = AlertSearchResults.new(alert).call
    search_results_ids = search_results.pluck(:id)
    alert.update(search_results: search_results_ids)
  end
end

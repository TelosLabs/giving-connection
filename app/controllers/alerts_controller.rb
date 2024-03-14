# frozen_string_literal: true

class AlertsController < ApplicationController
  include Pundit

  skip_before_action :authenticate_user!

  before_action :set_session_alert_params, only: [:create]

  def new
    @alert = Alert.new
    @filters = params[:filters]
    @filters_list = params[:filters_list]
    authorize @alert
  end

  def create
    new_alert = Alert.new(alert_params)
    authorize new_alert
    new_alert.user = current_user
    new_alert = clean_open_weekends(new_alert)
    if new_alert.save
      flash[:notice] = "Alert created successfully! Go to My Account to view or edit."
      redirect_to request.referer
    end
    update_alert_search_results(new_alert)
  end

  def edit
    @alert = Alert.find(params[:id])
    authorize @alert
  end

  def update
    @alert = Alert.find(params[:id])
    authorize @alert
    return unless @alert.update(alert_params)

    flash[:notice] = "Alert updated!"
    redirect_to my_account_path
  end

  def destroy
    @alert = Alert.find(params[:id])
    @alert.destroy
    authorize @alert
    flash[:notice] = "The alert was successfully deleted."
    redirect_to my_account_path
  end

  private

  def alert_params
    params.require(:alert)
      .permit(:filters, :distance, :open_now,
        :open_weekends, :keyword, :frequency,
        cause_ids: [], service_ids: [],
        beneficiary_subcategory_ids: [])
  end

  def clean_open_weekends(new_alert)
    new_alert.update!(open_weekends: false) unless new_alert.open_weekends == true
    new_alert
  end

  def update_alert_search_results(alert)
    search_results = AlertSearchResults.new(alert).call
    alert.update(search_results: search_results.pluck(:id))
  end

  def set_session_alert_params
    return if user_signed_in?

    session[:alert_params] = alert_params
    redirect_to user_session_path
  end
end

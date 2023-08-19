# frozen_string_literal: true

class AlertsController < ApplicationController
  include Pundit

  # Approach 2, crear el Alert after signin
  skip_before_action :authenticate_user!

  skip_after_action :verify_authorized

  # Approach 2, crear el Alert after signin
  before_action :set_session_alert, only: [:create]

  def new
    @alert = Alert.new
    @filters = params[:filters]
    @keywords = params[:keywords]
    @filters_list = params[:filters_list]
  end

  def create
    new_alert = Alert.new(alert_params)
    new_alert.user = current_user
    new_alert = clean_open_weekends(new_alert)
    if new_alert.save
      flash[:notice] = 'Alert created successfully! Go to My Account to view or edit.'
      redirect_to request.referer
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
    flash[:notice] = 'The alert was successfully deleted.'
    redirect_to my_account_path
  end

  private

  def alert_params
    params.require(:alert).permit(:filters, :distance, :city, :state,
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
    search_results_ids = search_results.pluck(:id)
    alert.update(search_results: search_results_ids)
  end

  # Approach 2, crear el Alert after signin
  def set_session_alert
    unless user_signed_in?
      session[:alert_params] = alert_params
      redirect_to user_session_path
    end
  end
end

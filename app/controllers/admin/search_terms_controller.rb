# frozen_string_literal: true

module Admin
  class SearchTermsController < Admin::ApplicationController
    # Most-recent searches first. Narrows by date range when the admin has
    # supplied date_from / date_to params. Both bounds are optional and the
    # filtering flows into the CSV export automatically via csv_export_scope.
    def scoped_resource
      base = super.order(created_at: :desc)
      base = base.where(created_at: date_from_param..) if date_from_param
      base = base.where(created_at: ..date_to_param) if date_to_param
      base
    end

    # Add a CSV export alongside the standard index view. The export runs through
    # the same search/filter pipeline as the HTML index so "Download CSV" gives
    # the admin the rows they are looking at, not the whole table.
    def index
      if request.format.csv?
        send_data SearchTerm.to_csv(csv_export_scope),
          filename: "search-terms-#{Time.zone.today.iso8601}.csv",
          type: "text/csv"
      else
        super
      end
    end

    private

    def csv_export_scope
      resources = filter_resources(scoped_resource, search_term: params[:search].to_s.strip)
      order.apply(resources)
    end

    def date_from_param
      @date_from_param ||= Date.parse(params[:date_from]) if params[:date_from].present?
    rescue ArgumentError
      nil
    end

    def date_to_param
      @date_to_param ||= Date.parse(params[:date_to]).end_of_day if params[:date_to].present?
    rescue ArgumentError
      nil
    end
  end
end

# frozen_string_literal: true

module Admin
  class SearchTermsController < Admin::ApplicationController
    # Most-recent searches first on the index page.
    def scoped_resource
      super.order(created_at: :desc)
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
  end
end

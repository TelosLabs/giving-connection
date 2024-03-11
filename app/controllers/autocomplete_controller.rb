class AutocompleteController < ApplicationController
  skip_before_action :authenticate_user!

  include Pundit

  skip_after_action :verify_policy_scoped
  skip_after_action :verify_authorized

  def index
    @suggestions = PgSearch.multisearch(params[:q]).map do |record|
      record.searchable.name
    end.uniq.sort

    render layout: false
  end
end

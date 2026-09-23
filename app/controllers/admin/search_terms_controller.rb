# frozen_string_literal: true

module Admin
  class SearchTermsController < Admin::ApplicationController
    # Most-recent searches first on the index page.
    def scoped_resource
      super.order(created_at: :desc)
    end
  end
end

# frozen_string_literal: true

# navbar view component
# rubocop:disable Style/ClassAndModuleChildren
# rubocop:disable Lint/MissingSuper
class Navbar::Component < ApplicationViewComponent
  def initialize(signed_in:)
    @signed_in = signed_in
  end

  def non_sticky_paths
    request.env["PATH_INFO"] == "/searches" || request.env["PATH_INFO"] == "/my_account"
  end
end

# rubocop:enable Style/ClassAndModuleChildren
# rubocop:enable Lint/MissingSuper

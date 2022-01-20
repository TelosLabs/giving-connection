# frozen_string_literal: true

# navbar view component
# rubocop:disable Style/ClassAndModuleChildren
# rubocop:disable Lint/MissingSuper
class Navbar::Component < ViewComponent::Base
  def initialize(signed_in:)
    @signed_in = signed_in
  end
end

# rubocop:enable Style/ClassAndModuleChildren
# rubocop:enable Lint/MissingSuper

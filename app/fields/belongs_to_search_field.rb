# frozen_string_literal: true

require "administrate/field/belongs_to"

# Adapted from the (Administrate 0.x-only, unmaintained) gem
# administrate-field-belongs_to_search.
class BelongsToSearchField < Administrate::Field::BelongsTo
  def associated_resource_options
    return [] unless data

    [[display_candidate_resource(data), data.id]]
  end
end

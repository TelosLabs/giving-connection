# frozen_string_literal: true

require "administrate/field/base"

class InKindDonationItemsField < Administrate::Field::Base
  def selected_items
    Array(data)
  end

  def options
    Organizations::Constants::IN_KIND_DONATION_ITEMS
  end

  def selected_labels
    selected_items.filter_map { |item_key| options[item_key.to_s] }
  end

  def to_s
    selected_labels.join(", ")
  end
end

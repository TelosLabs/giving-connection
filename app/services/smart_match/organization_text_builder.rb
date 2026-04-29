# frozen_string_literal: true

module SmartMatch
  class OrganizationTextBuilder < ApplicationService
    MAX_LENGTH = 1500

    attr_reader :organization

    def initialize(organization:)
      @organization = organization
    end

    def call
      parts = [
        organization.name,
        organization.mission_statement_en,
        organization.vision_statement_en,
        organization.tagline_en,
        organization.causes.pluck(:name).join(", "),
        organization.beneficiary_subcategories.pluck(:name).join(", "),
        location_text
      ]

      text = parts.compact_blank.join(" | ")
      return nil if text.blank?

      text.truncate(MAX_LENGTH)
    end

    private

    def location_text
      organization.main_location&.address
    end
  end
end

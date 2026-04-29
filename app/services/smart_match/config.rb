# frozen_string_literal: true

module SmartMatch
  module Config
    def self.matching_rules
      @matching_rules ||= YAML.load_file(Rails.root.join("config/matching_rules.yml"))
    end

    def self.city_centroids
      @city_centroids ||= YAML.load_file(Rails.root.join("config/city_centroids.yml"))
    end
  end
end

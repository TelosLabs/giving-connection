# frozen_string_literal: true

namespace :smart_match do
  desc "Generate embeddings for all active organizations"
  task embed_all: :environment do
    SmartMatch::EmbedAllOrganizationsJob.perform_now
  end
end

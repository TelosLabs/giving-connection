# frozen_string_literal: true

namespace :smart_match do
  desc "Generate embeddings for all active organizations"
  task embed_all: :environment do
    SmartMatch::EmbedAllOrganizationsJob.perform_now
  end

  # 50 US states + DC + PR (only states the matching pipeline can reach today).
  US_STATE_CODES = %w[
    AL AK AZ AR CA CO CT DE FL GA HI ID IL IN IA KS KY LA ME MD MA MI MN MS MO
    MT NE NV NH NJ NM NY NC ND OH OK OR PA RI SC SD TN TX UT VT VA WA WV WI WY
    DC PR
  ].freeze
  US_STATE_RE = /\b(#{US_STATE_CODES.join("|")})\b/

  desc "Backfill locations.state_code by parsing the trailing 2-letter state from `address`. Idempotent; only fills NULL rows."
  task backfill_location_state_codes: :environment do
    scope = Location.where(state_code: nil)
    total = scope.count
    filled = 0
    skipped = 0

    scope.find_each(batch_size: 200) do |loc|
      match = loc.address.to_s.upcase.match(US_STATE_RE)
      if match
        loc.update_columns(state_code: match[1])
        filled += 1
      else
        skipped += 1
      end
    end

    puts({
      total_null_rows: total,
      filled: filled,
      skipped_no_match: skipped,
      still_null: Location.where(state_code: nil).count
    }.to_json)
  end
end

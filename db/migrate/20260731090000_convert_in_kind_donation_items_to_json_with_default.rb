class ConvertInKindDonationItemsToJsonWithDefault < ActiveRecord::Migration[7.2]
  class MigrationOrganization < ActiveRecord::Base
    self.table_name = "organizations"
  end

  def up
    # The column predates the key-based redesign, so some rows may still hold
    # the old free-text format (e.g. "Diapers\nClothing...") instead of valid
    # JSON. That data can't be reliably mapped to today's stable keys, so we
    # normalize anything that isn't already a valid JSON array down to [].
    MigrationOrganization.reset_column_information
    MigrationOrganization.find_each do |organization|
      raw_value = organization.read_attribute(:in_kind_donation_items)
      parsed = begin
        JSON.parse(raw_value.to_s)
      rescue JSON::ParserError
        nil
      end
      normalized = parsed.is_a?(Array) ? parsed : []
      organization.update_column(:in_kind_donation_items, normalized.to_json)
    end

    change_column :organizations, :in_kind_donation_items, :json,
      default: [], using: "in_kind_donation_items::json"
  end

  def down
    change_column :organizations, :in_kind_donation_items, :text, default: nil
  end
end

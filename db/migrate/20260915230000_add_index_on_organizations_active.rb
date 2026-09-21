# frozen_string_literal: true

# `Location.active` (joined on every search request) filters on this column.
class AddIndexOnOrganizationsActive < ActiveRecord::Migration[7.2]
  disable_ddl_transaction!

  def change
    add_index :organizations, :active, algorithm: :concurrently, if_not_exists: true
  end
end

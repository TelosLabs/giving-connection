# frozen_string_literal: true

class CreateOrganizationCategories < ActiveRecord::Migration[6.1]
  def change
    create_table :organization_categories do |t|
      t.references :organization, null: false, foreign_key: true
      t.references :category, null: false, foreign_key: true

      t.timestamps
    end
  end
end

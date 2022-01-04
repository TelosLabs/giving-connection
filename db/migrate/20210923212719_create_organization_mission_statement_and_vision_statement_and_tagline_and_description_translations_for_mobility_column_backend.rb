# frozen_string_literal: true

# This migration comes from active_storage
class CreateOrganizationMissionStatementAndVisionStatementAndTaglineAndDescriptionTranslationsForMobilityColumnBackend < ActiveRecord::Migration[6.1]
  def change
    add_column :organizations, :mission_statement_en, :text, null: false
    add_column :organizations, :mission_statement_es, :text
    add_column :organizations, :vision_statement_en, :text
    add_column :organizations, :vision_statement_es, :text
    add_column :organizations, :tagline_en, :text
    add_column :organizations, :tagline_es, :text
    add_column :organizations, :description_en, :text
    add_column :organizations, :description_es, :text

    add_index :organizations, :mission_statement_en
    add_index :organizations, :vision_statement_en
    add_index :organizations, :tagline_en
    add_index :organizations, :description_en
  end
end

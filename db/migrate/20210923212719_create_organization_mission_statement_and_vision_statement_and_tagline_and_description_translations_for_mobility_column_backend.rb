class CreateOrganizationMissionStatementAndVisionStatementAndTaglineAndDescriptionTranslationsForMobilityColumnBackend < ActiveRecord::Migration[6.1]
  def change
    add_column :organizations, :mission_statement_en, :text
    add_column :organizations, :mission_statement_es, :text
    add_column :organizations, :vision_statement_en, :text
    add_column :organizations, :vision_statement_es, :text
    add_column :organizations, :tagline_en, :text
    add_column :organizations, :tagline_es, :text
    add_column :organizations, :description_en, :text
    add_column :organizations, :description_es, :text
  end
end

# frozen_string_literal: true

class CreateSocialMedias < ActiveRecord::Migration[6.1]
  def change
    create_table :social_medias do |t|
      t.string :facebook
      t.string :instagram
      t.string :twitter
      t.string :linkedin
      t.string :youtube
      t.string :blog
      t.references :organization, null: false, foreign_key: true

      t.timestamps
    end
  end
end

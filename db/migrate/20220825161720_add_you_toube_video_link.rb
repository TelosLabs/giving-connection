class AddYouToubeVideoLink < ActiveRecord::Migration[6.1]
  def change
    add_column :locations, :youtube_vide_link, :string
  end
end

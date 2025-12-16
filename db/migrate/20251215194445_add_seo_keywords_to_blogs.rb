class AddSeoKeywordsToBlogs < ActiveRecord::Migration[7.2]
  def change
    add_column :blogs, :seo_keywords, :text
  end
end

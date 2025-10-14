class BackfillPublishedOnBlogsReversible < ActiveRecord::Migration[7.2]
  def up
    Blog.where(published: nil).update_all(published: false)
  end

  def down
    Blog.where(published: false).update_all(published: nil)
  end
end

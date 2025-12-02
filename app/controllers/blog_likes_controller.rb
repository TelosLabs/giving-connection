class BlogLikesController < ApplicationController
  before_action :require_user!

  include Pundit
  skip_after_action :verify_policy_scoped
  skip_after_action :verify_authorized

  def create
    @blog = Blog.find(params[:blog_id])
    @blog_like = current_user.blog_likes.find_or_initialize_by(blog: @blog)

    if @blog_like.persisted? || @blog_like.save
      @likes_count = @blog.blog_likes.count
      respond_to do |f|
        f.turbo_stream
        f.html { redirect_back fallback_location: blog_path(@blog) }
      end
    else
      redirect_back fallback_location: blog_path(@blog), alert: @blog_like.errors.full_messages.to_sentence
    end
  end

  def destroy
    @blog_like = current_user.blog_likes.find(params[:id])
    @blog = @blog_like.blog

    if @blog_like.destroy
      @likes_count = @blog.blog_likes.count
      respond_to do |f|
        f.turbo_stream
        f.html { redirect_back fallback_location: blog_path(@blog) }
      end
    else
      redirect_back fallback_location: blog_path(@blog), alert: "Could not unlike"
    end
  end

  private

  def require_user!
    return if user_signed_in?
    redirect_to user_session_path
  end
end

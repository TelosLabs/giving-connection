# frozen_string_literal: true

class FavoriteBlogsController < ApplicationController
  skip_before_action :authenticate_user!
  before_action :set_session_favorite

  include Pundit
  skip_after_action :verify_policy_scoped
  skip_after_action :verify_authorized

  def create
    @blog = Blog.find(params[:blog_id])
    @new_favorite_blog = FavoriteBlog.new(blog: @blog, user: current_user)

    @new_favorite_blog.save
  end

  def destroy
    @favorite_blog = current_user.fav_blogs.find(params[:id])
    @user = @favorite_blog.user
    @blog = @favorite_blog.blog

    @favorite_blog.destroy
  end

  private

  def set_session_favorite
    unless user_signed_in?
      session[:fav_blog_blog_id] = params[:blog_id]
      redirect_to user_session_path
    end
  end

end

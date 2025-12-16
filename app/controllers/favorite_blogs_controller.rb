# frozen_string_literal: true

class FavoriteBlogsController < ApplicationController
  before_action :authenticate_user!

  before_action :save_intended_blog, only: [:create]

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

  def save_intended_blog
    session[:intended_blog_id] = params[:blog_id] if params[:blog_id].present?
  end
end

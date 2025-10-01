# app/controllers/blogs_controller.rb
class BlogsController < ApplicationController
  after_action :verify_policy_scoped, only: [:index]
  before_action :set_blog, only: [:show, :edit, :update, :destroy]

  # GET /blogs
  def index
    @blogs = policy_scope(Blog)
  end

  # GET /blogs/1
  def show
    authorize @blog
  end

  # GET /blogs/new
  def new
    @blog = Blog.new
    # If logged in, pre-assign current user; otherwise leave nil (optional)
    @blog.user = current_user if user_signed_in?
    authorize @blog
  end

  # GET /blogs/1/edit
  def edit
    authorize @blog
  end

  # POST /blogs
  def create
    @blog = Blog.new(blog_params)
    # Author is optional: set it only if there's a current_user
    @blog.user = current_user if user_signed_in?
    authorize @blog

    if @blog.save
      redirect_to @blog, notice: 'Blog was successfully created.'
    else
      render :new, status: :unprocessable_entity
    end
  end

  # PATCH/PUT /blogs/1
  def update
    authorize @blog
    if @blog.update(blog_params)
      # Note: we do NOT change @blog.user here; author stays whatever it was.
      redirect_to @blog, notice: 'Blog was successfully updated.'
    else
      render :edit, status: :unprocessable_entity
    end
  end

  # DELETE /blogs/1
  def destroy
    authorize @blog
    @blog.destroy
    redirect_to blogs_url, notice: 'Blog was successfully deleted.'
  end

  private

  def set_blog
    @blog = Blog.find(params[:id])
  end

  # Do NOT permit :user_id; author gets set from current_user when present.
  def blog_params
    params.require(:blog).permit(:title, :content, :name, :email, :impact_tag, :cover_image)
  end
end

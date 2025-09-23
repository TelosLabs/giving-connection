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
    authorize @blog
  end

  # GET /blogs/1/edit
  def edit
    authorize @blog
  end

  # POST /blogs
  def create
    @blog = Blog.new(blog_params)
    authorize @blog

    if @blog.save
      redirect_to @blog, notice: 'Blog was successfully created.'
    else
      render :new
    end
  end

  # PATCH/PUT /blogs/1
  def update
    authorize @blog
    
    if @blog.update(blog_params)
      redirect_to @blog, notice: 'Blog was successfully updated.'
    else
      render :edit
    end
  end

  # DELETE /blogs/1
  def destroy
    authorize @blog
    @blog.destroy
    redirect_to blogs_url, notice: 'Blog was successfully deleted.'
  end

  private

  # Find the blog for show, edit, update, destroy actions
  def set_blog
    @blog = Blog.find(params[:id])
  end

  # Strong parameters - only allow these fields
  def blog_params
    params.require(:blog).permit(:title, :content, :author, :published)
  end
end
# app/controllers/blogs_controller.rb
class BlogsController < ApplicationController
  after_action :verify_policy_scoped, only: [:index]
  after_action :track_blog_view, only: :show
  before_action :set_blog, only: [:show, :edit, :update, :destroy]
  skip_before_action :authenticate_user!, only: [:index, :show, :new, :create]

  # GET /blogs
  def index
    @blogs = policy_scope(Blog).order(created_at: :desc)
  end

  # GET /blogs/1
  def show
    authorize @blog
    @comment  = @blog.comments.build
    @comments = @blog.comments.includes(:user).order(created_at: :desc)
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
    @blog.user = current_user if user_signed_in?
    authorize @blog

    if @blog.save
      respond_to do |f|
        f.turbo_stream
        f.html { redirect_to blogs_path, notice: "Thanks for sharing your story!" }
      end
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

  def blog_params
    params.require(:blog).permit(:title, :content, :name, :email, :impact_tag, :cover_image, :share_consent)
  end

  def track_blog_view
    user_agent = request.user_agent.to_s.downcase
    return if @blog.nil? || user_agent.match?(/bot|spider|crawl/)
    
    session[:viewed_blog_ids] ||= []
    return if session[:viewed_blog_ids].include?(@blog.id)

    Blog.increment_counter(:views_count, @blog.id)

    session[:viewed_blog_ids] << @blog.id
    session[:viewed_blog_ids] = session[:viewed_blog_ids].last(200)
  end
end

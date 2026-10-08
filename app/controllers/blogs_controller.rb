class BlogsController < ApplicationController
  after_action :verify_policy_scoped, only: [:index]
  after_action :track_blog_view, only: :show
  before_action :set_blog, only: [:show, :edit, :update, :destroy]
  skip_before_action :authenticate_user!, only: [:index, :show, :new, :create]

  def index
    @selected_tag = Blog::BLOG_TAG_OPTIONS.include?(params[:blog_tag]) ? params[:blog_tag] : "all"
    # Named :q, not :search -- Locationable (included globally) treats a
    # top-level `search` param as a {lat:, lon:, city:} hash for geolocation
    # and calls params.dig("search", "lat"), which raises on a plain string.
    @search = params[:q].to_s.strip

    searched = apply_search(policy_scope(Blog), @search)
    @blogs = ((@selected_tag == "all") ? searched : searched.where(blog_tag: @selected_tag)).order(created_at: :desc)

    # Every tab's count, filtered by the current search term, so switching
    # tabs mid-search shows accurate counts instead of the unfiltered total.
    # One grouped query instead of one ILIKE-scan-plus-joins query per tag.
    counts_by_tag = searched.group(:blog_tag).count
    @tag_counts = (["all"] + Blog::BLOG_TAG_OPTIONS).index_with { |tag|
      (tag == "all") ? counts_by_tag.values.sum : counts_by_tag.fetch(tag, 0)
    }
  end

  def show
    authorize @blog
    @comment = @blog.comments.build
    @comments = @blog.comments.includes(:user).order(created_at: :desc)
    @related_blogs = @blog.related_blogs(limit: 3)
  end

  def new
    @blog = Blog.new
    @blog.user = current_user if user_signed_in?
    @impact_tag_options = Blog::IMPACT_TAG_OPTIONS
    authorize @blog
  end

  def edit
    @impact_tag_options = Blog::IMPACT_TAG_OPTIONS
    authorize @blog
  end

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

  def update
    authorize @blog
    if @blog.update(blog_params)
      redirect_to @blog, notice: "Blog was successfully updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    authorize @blog
    @blog.destroy
    redirect_to blogs_url, notice: "Blog was successfully deleted."
  end

  private

  # ILIKE across the same fields the old client-side Fuse.js search covered
  # (title, content, topic, author), now server-side so the per-tab counts
  # and the rendered list always agree. Blog volume is small enough that a
  # plain scan needs no index/tsvector investment.
  def apply_search(scope, term)
    return scope if term.blank?

    scope.left_joins(:user, :rich_text_content).where(
      "blogs.title ILIKE :term OR blogs.topic ILIKE :term OR blogs.name ILIKE :term " \
      "OR users.name ILIKE :term OR action_text_rich_texts.body ILIKE :term",
      term: "%#{term.gsub(/[\\%_]/) { |c| "\\#{c}" }}%"
    )
  end

  def set_blog
    @blog = Blog.find(params[:id])
  end

  def blog_params
    params.require(:blog).permit(:title, :content, :name, :email, :blog_tag, :topic, :share_consent, images: [], impact_tag: [])
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

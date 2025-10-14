class CommentsController < ApplicationController
  skip_before_action :authenticate_user!, only: [:show]
  before_action :require_login, only: [:create, :edit, :update, :destroy]
  before_action :set_blog
  before_action :set_comment, only: [:show, :edit, :update, :destroy]
  before_action :authorize_owner!, only: [:edit, :update, :destroy]

  def create
    @comment = @blog.comments.build(comment_params.merge(user: current_user))
    authorize @comment

    if @comment.save
      redirect_to blog_path(@blog), notice: "Comment posted."
    else
      @comments = @blog.comments.includes(:user).order(created_at: :desc)
      render "blogs/show", status: :unprocessable_entity
    end
  end

  def show
    render partial: "comments/comment", locals: {comment: @comment}
  end

  def edit
    authorize @comment
  end

  def update
    authorize @comment
    if @comment.update(comment_params)
      if turbo_frame_request?
        render partial: "comments/comment", locals: {comment: @comment}, status: :ok
      else
        redirect_to blog_path(@blog), notice: "Comment updated."
      end
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    authorize @comment
    @comment.destroy
    redirect_to blog_path(@blog), notice: "Comment deleted."
  end

  private

  def set_blog
    @blog = Blog.find(params[:blog_id])
  end

  def set_comment
    @comment = @blog.comments.find(params[:id])
  end

  def comment_params
    params.require(:comment).permit(:body)
  end

  def require_login
    redirect_to new_session_path, alert: "Please sign in." unless current_user
  end

  def authorize_owner!
    redirect_to blog_path(@blog), alert: "Not authorized." unless @comment.user_id == current_user&.id
  end
end

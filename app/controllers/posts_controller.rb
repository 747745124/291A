class PostsController < ApplicationController
  layout "main"
  before_action :set_post, only: [ :show, :edit, :update, :destroy ]
  before_action :check_owner, only: [ :edit, :update, :destroy ]

  def index
    @posts = Post.includes(:user, :comments)
                 .order(created_at: :desc)

    if params[:username].present?
      @posts = @posts.joins(:user)
                    .where("users.username LIKE ?", "%#{params[:username]}%")
    end
  end

  def show
    @comment = Comment.new
  rescue ActiveRecord::RecordNotFound
    render file: Rails.public_path.join("404.html"), status: :not_found, layout: false
  end

  def new
    @post = current_user.posts.build
  end

  def create
    @post = current_user.posts.build(post_params)
    if @post.save
      redirect_to @post, notice: "Post created successfully."
    else
      render :new
    end
  end

  def edit
  end

  def update
    if @post.update(post_params)
      redirect_to @post, notice: "Post updated successfully."
    else
      render :edit
    end
  end

  def destroy
    @post.destroy
    redirect_to posts_path, notice: "Post deleted successfully."
  end

  private

  def post_params
    params.require(:post).permit(:content)
  end

  def set_post
    @post = Post.find_by(id: params[:id])
    unless @post
      redirect_to posts_path, alert: "Post not found."
    end
  end

  def check_owner
    unless @post.user == current_user
      redirect_to posts_path, alert: "You can only edit your own posts."
    end
  end
end

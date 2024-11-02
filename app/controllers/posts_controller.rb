class PostsController < ApplicationController
  def index
    if params[:username].present?
      @posts = Post.filter_by_username(params[:username])
    else
      @posts = Post.all
    end
  end
end

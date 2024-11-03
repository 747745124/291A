class CommentsController < ApplicationController
  def create
    @post = Post.find(params[:post_id])
    @comment = @post.comments.build(comment_params)
    @comment.user = current_user


      if @comment.save
        flash[:notice] = "Comment added successfully!"
        respond_to do |format|
        format.turbo_stream {
          render turbo_stream: turbo_stream.append(
            "comments",
            partial: "comments/comment",
            locals: { comment: @comment }
          )
        }
        format.html { redirect_to @post }
      end

      elsif contains_prohibited_words?(@comment.content)
        @comment.errors.add(:content, "contains prohibited words")
        respond_to do |format|
          flash.now[:alert] = "There was a problem with your comment."
          format.html { render "posts/show" }
          format.turbo_stream { render_flash }
        end
      else
        flash.now[:alert] = "There was a problem with your comment."
        respond_to do |format|
          format.turbo_stream { render_flash }
          format.html { render "posts/show" }
      end
      end
  end

  private

  def comment_params
    params.require(:comment).permit(:content)
  rescue ActionController::ParameterMissing
    flash.now[:alert] = "Comment content cannot be empty"
    {}
  end

  def contains_prohibited_words?(content)
    prohibited_words = [ "trump", "harris" ] # Replace with your list
    prohibited_words.any? { |word| content.include?(word) }
  end

  def render_flash
    render turbo_stream: turbo_stream.replace("flash", partial: "shared/flash")
  end
end

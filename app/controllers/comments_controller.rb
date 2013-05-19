class CommentsController < ProjectController
  before_filter :load_project_tweet

  def new
    @comment = @tweet.comments.build
    # NOTE: renders html or js
  end

  def create
    @comment = @tweet.comments.build(comment_params)
    @comment.user = current_user

    if @comment.save
      redirect_to project_tweet_path(@project, @tweet), notice: 'Comment has been created.'
    else
      render :new
    end
  end

  private

  def comment_params
    params.require(:comment).permit(:text)
  end
end

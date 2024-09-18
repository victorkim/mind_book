class CommentsController < ApplicationController
    before_action :set_project #This method is called before each action. It finds the project that the comment belongs to, using the project_id from the URL.
    before_action :set_comment, only: [:edit, :update, :destroy] #This method is called before the edit, update, and destroy actions. It finds the specific comment within the project by its id.
  
      # Display all comments for a specific project
    def index
        @comments = @project.comments
    end
    
    # Create a new comment and associate it with a project and user
    def create
      @comment = @project.comments.build(comment_params)
      @comment.user = current_user
  
      if @comment.save
        redirect_to @project, notice: 'Comment was successfully added.'
      else
        redirect_to @project, alert: 'Failed to add comment.'
      end
    end
  
    # DELETE a comment
    def destroy
      @comment.destroy
      redirect_to @project, notice: 'Comment was successfully deleted.'
    end
  
    # Action to render the edit form
    def edit
      # Renders the edit form for the selected comment
    end
  
    # Update a comment
    def update
      if @comment.update(comment_params)
        redirect_to @project, notice: 'Comment was successfully updated.'
      else
        render :edit
      end
    end
  
    private
  
    # Find the project based on the project_id from the URL
    def set_project
      @project = Project.find(params[:project_id])
    end
  
    # Find the specific comment within the project
    def set_comment
      @comment = @project.comments.find(params[:id])
    end
  
    # Strong parameters: permit only the necessary attributes to prevent mass assignment vulnerabilities
    def comment_params
      params.require(:comment).permit(:body)
    end
  end
  
class CommentsController < ApplicationController
  before_action :authenticate_user!, except: [:index, :weekly] #checks if user is authenticated whenever they try to run any operation besides index
  before_action :set_parent, only: [:create, :edit, :update, :destroy, :index, :weekly] #This method is called before each action. It finds the parent that the comment belongs to, using the project_id/channel_id from the URL.
  before_action :set_comment, only: [:edit, :update, :destroy] #This method is called before the edit, update, and destroy actions. It finds the specific comment within the project by its id.
  
  def index
      @comments = @parents.comments #GET request that displays all comments for a specific project (which is specified using set_project)
  end
      
  def create
    @comment = Comment.new(comment_params)
    @comment.user = current_user
    @comment.date ||= Date.today
    
    # Set the appropriate associations based on the parent
    if @parent.is_a?(Channel)
      @comment.channel = @parent
      # Ensure a project is selected when creating from a channel
      if comment_params[:project_id].present?
        @comment.project_id = comment_params[:project_id]
      else
        redirect_to @parent, alert: 'Please select a project for this comment.' and return
      end
    elsif @parent.is_a?(Project)
      @comment.project = @parent
      # Optional channel association when creating from a project
      if comment_params[:channel_id].present?
        @comment.channel_id = comment_params[:channel_id]
      end
    end
  
    if @comment.save
      redirect_to @parent, notice: 'Comment was successfully added.'
    else
      redirect_to @parent, alert: "Failed to add comment: #{@comment.errors.full_messages.join(', ')}"
    end
  end   
  
  def edit
    @comment = @parent.comments.find(params[:id])
    respond_to do |format|
      format.turbo_stream { render "edit" }
      format.html
    end
  end  
    
  def update
    if @comment.update(comment_params)
      respond_to do |format| 
        format.turbo_stream do 
          render turbo_stream: [
            turbo_stream.replace("comment_#{@comment.id}_timeline", 
                                partial: "comments/comment", 
                                locals: { comment: @comment, context: :timeline, parent: @parent }),
            turbo_stream.replace("comment_#{@comment.id}_list", 
                                partial: "comments/comment", 
                                locals: { comment: @comment, context: :list, parent: @parent }),
            turbo_stream.replace("edit_comment_modal", 
                                partial: "comments/empty_modal")
          ] 
        end      
        format.html { redirect_to @parent, notice: 'Comment was successfully updated.' }
      end
    else
      render :edit
    end
  end

  def destroy #DELETE action that deletes a comment
    @comment.destroy
    redirect_to @parent, notice: 'Comment was successfully deleted.' #When deletion is successful, it redirects to the index view of the project's comments
  end

  def weekly
    @project = Project.find(params[:project_id])
    week_start = DateTime.parse(params[:week_start])
    week_end = week_start + 1.week
  
    @comments = @project.comments.where(created_at: week_start...week_end)
  
    respond_to do |format|
      format.turbo_stream {
        render partial: 'comments/comments_weekly', locals: { project: @project, comments: @comments, week_start: week_start }
      }
      format.html {
        render partial: 'comments/comments_weekly', locals: { project: @project, comments: @comments, week_start: week_start }
      }
    end
  end
    
  private #This section defines helper methods that are used internally within the controller. These methods aren't accessible from outside the controller (that's why they're marked as private), but they are crucial for managing the flow of data. The set_projects and set_comment methods used before actions (lines 2 and 3) are defined below
  
    #none of the @project syntax above the private line would make sense or mean anything if it wasn't for this line below
    def set_parent
      if params[:project_id].present?
        @parent = Project.find(params[:project_id])
      elsif params[:channel_id].present?
        @parent = Channel.find(params[:channel_id])
      else
        # Optional: handle the case when neither is present
        @parent = nil
      end
    end

    # Now that @parent is set, we find the comment from its association.
    def set_comment
      @comment = @parent.comments.find(params[:id])
    end
      
    def comment_params #Strong parameters: permit only the necessary attributes to prevent mass assignment vulnerabilities
      params.require(:comment).permit(:body, :date, :project_id, :channel_id) #params.require(:comment) ensures that the request contains a :comment key. For example, if you're submitting a form to create or update a comment, Rails expects the form data to be nested under the :comment key. While the .permit(:body) defines which attributes of the comment are allowed to be submitted. In this case, only the body field of the comment is allowed.
    end
end
  
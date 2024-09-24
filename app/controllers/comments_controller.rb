class CommentsController < ApplicationController
  before_action :set_project #This method is called before each action. It finds the project that the comment belongs to, using the project_id from the URL.
  before_action :set_comment, only: [:edit, :update, :destroy] #This method is called before the edit, update, and destroy actions. It finds the specific comment within the project by its id.
  
  def index
      @comments = @project.comments #GET request that displays all comments for a specific project (which is specified using set_project)
  end
    
  def create # POST request that creates a new comment and associate it with a project and user
    @comment = @project.comments.build(comment_params) #Ensure the association between comment and project
    @comment.user = current_user #It sets the user of the comment to the current_user
      if @comment.save #It tries to save the comment. If successful, it redirects to the project page; if not, it re-renders the project page with validation errors.
        redirect_to @project, notice: 'Comment was successfully added.'
      else
        redirect_to @project, alert: 'Failed to add comment.'
      end
    end

  def edit #GET action to render the edit form
    @comment = @project.comments.find(params[:id]) #The action doesn't explicitly return any data but renders an edit form where the user can modify the comment's text.
  end
  
  def update #PATCH/PUT action to update an existing comment with new information. The comment is retrieved using the set_comment method
    if @comment.update(comment_params) #The comment is updated with the parameters submitted by the user (comment_params)
      redirect_to @project, notice: 'Comment was successfully updated.' #If the update is successful, it redirects to the index view of the project's comments.
    else
      render :edit #If the update fails (e.g., validation errors), it re-renders the edit form with error messages.
    end
  end

  def destroy #DELETE action that deletes a comment
    @comment.destroy
    redirect_to @project, notice: 'Comment was successfully deleted.' #When deletion is successful, it redirects to the index view of the project's comments
  end
    
  private #This section defines helper methods that are used internally within the controller. These methods aren't accessible from outside the controller (that's why they're marked as private), but they are crucial for managing the flow of data. The set_projects and set_comment methods used before actions (lines 2 and 3) are defined below
  
  #none of the @project syntax above the private line would make sense or mean anything if it wasn't for this line below
  def set_project #Find the project based on the project_id from the URL
    @project = Project.find(params[:project_id]) #This method retrieves the project from the database using Project.find and assigns it to the @project instance variable. The @project variable is then accessible in the controller actions that require it (like creating or listing comments for that project).
  end

  def set_comment #This method finds a specific comment within the context of the current project.
    @comment = @project.comments.find(params[:id])
  end
  
  def comment_params #Strong parameters: permit only the necessary attributes to prevent mass assignment vulnerabilities
    params.require(:comment).permit(:body) #params.require(:comment) ensures that the request contains a :comment key. For example, if you're submitting a form to create or update a comment, Rails expects the form data to be nested under the :comment key. While the .permit(:body) defines which attributes of the comment are allowed to be submitted. In this case, only the body field of the comment is allowed.
  end
end
  
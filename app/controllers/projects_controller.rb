class ProjectsController < ApplicationController
  before_action :authenticate_user!, except: [:index, :show] #checks if user is authenticated whenever they try to run any operation besides index and show
  before_action :set_project, only: %i[ show edit update destroy ] #instantiates the project based on the ID from parameters for actions that need it (for show, edit, update and destroy without repeating code)

  def index
    service = ProjectsTimelineDataService.new(params) #Initialize the ProjectsTimelineDataService with request parameters
    timeline_result = service.call #Execute the service and store the returned hash in timeline_result
    
    @projects = timeline_result[:projects] #Assign the filtered projects from the service result to @projects for use in the view
    @timeline_data = timeline_result[:timeline_data] #Assign the generated timeline data from the service result to @timeline_data for use in the view
    @week_starts = timeline_result[:week_starts] #Assign the array of week start dates from the service result to @week_starts for use in the view
  end
  
  def show
    @comment = @project.comments.build #Initialize (=prepare) a new comment for the comment form in the view, which allows users to add a new comment directly from the project show page.
    @comments = @project.comments.order(created_at: :desc) #Retrieve all comments for the project, ordered by creation date descending
    @comments_by_date = @comments.group_by { |comment| comment.created_at.to_date } #Group comments by their creation date

    starting_date = @project.start_date.beginning_of_week #Determine the starting and ending dates for the comments timeline
    ending_date = Date.today.end_of_week

    @weeks_data = CommentsTimelineDataService.new(@project, starting_date, ending_date).call #Initialize the comments timeline data service and retrieve timeline data
  end

  def new
    @project = Project.new
  end  

  def edit
  end
 
  def create
    @project = current_user.projects.build(project_params) #Build a new project associated with the current user using permitted parameters
    respond_to do |format|
      if @project.save
        format.turbo_stream do
          render turbo_stream: [
            turbo_stream.prepend("all-projects", partial: "projects/project_card", locals: { project: @project }), #Respond with Turbo Streams for real-time updates and adding the new record at the top
            turbo_stream.remove("new_project_modal") #This removes the modal after success
          ]
        end
        format.html { redirect_to project_url(@project), notice: "Project was successfully created." } #Redirect to the project page with a success notice for HTML requests
        format.json { render :show, status: :created, location: @project } #Render the project as JSON with a created status for JSON requests
      else
        format.html { render :new, status: :unprocessable_entity } #Render the new template with errors for HTML requests
        format.json { render json: @project.errors, status: :unprocessable_entity } #Render errors as JSON for JSON requests
      end
    end
  end

  def update
    respond_to do |format|
      if @project.update(project_params)
        format.html { redirect_to project_url(@project), notice: "Project was successfully updated." } #Redirect to the project page with a success notice for HTML requests
        format.json { render :show, status: :ok, location: @project } #Render the project as JSON with an OK status for JSON requests
      else
        format.html { render :edit, status: :unprocessable_entity } #Render the edit template with errors for HTML requests
        format.json { render json: @project.errors, status: :unprocessable_entity } #Render errors as JSON for JSON requests
      end
    end
  end

  def destroy
    @project.destroy!

    respond_to do |format|
      format.html { redirect_to projects_url, notice: "Project was successfully destroyed." }
      format.json { head :no_content }
    end
  end

  def weekly_comments
    week_start = params[:week_start] #Fetch comments based on the week_start parameter
  end    

  private #methods defined below the "private" line are only accessible within the class itself (meaning they cannot be directly invoked as actions via a web request and we ensure this is only used internally and not accessible via a URL). These methods are implementation details used to support the public controller actions. Exposing these methods as actions would create unnecessary and potentially insecure entry points into your application.
    
    def set_project #Use callbacks to share common setup or constraints between actions.
      @project = Project.find(params[:id])
    end

    def project_params #defines the permitted parameters for a Project object. It ensures only safe and allowed attributes (e.g., :name, :description, etc.) can be passed to your model when creating or updating a project.
      params.require(:project).permit(:name, :description, :start_date, :end_date, :department)
    end 

end

class ProjectsController < ApplicationController
  before_action :authenticate_user!, except: [:index, :show] #checks if user is authenticated whenever they try to run any operation besides index and show
  before_action :set_project, only: %i[ show edit update destroy ]

  # GET /projects or /projects.json
  def index
    @projects = Project.all
  
    # Apply Department Filter
    if params[:department].present? && params[:department] != 'All Departments'
      @projects = @projects.where(department: params[:department])
    end
  
    # Initialize start_date and end_date
    if params[:start_date].present?
      begin
        start_date = Date.parse(params[:start_date]).beginning_of_week
      rescue ArgumentError
        start_date = 8.weeks.ago.beginning_of_week.to_date
      end
    else
      start_date = 8.weeks.ago.beginning_of_week.to_date
    end
  
    if params[:end_date].present?
      begin
        end_date = Date.parse(params[:end_date]).end_of_week
      rescue ArgumentError
        end_date = Date.today.end_of_week
      end
    else
      end_date = Date.today.end_of_week
    end
  
    # Ensure start_date and end_date are Date objects
    start_date = start_date.to_date
    end_date = end_date.to_date
  
    # Filter projects based on start_date (if needed)
    @projects = @projects.where(start_date: start_date..end_date)
  
    # Collect comments data for the timeline
    @weeks_data = collect_weeks_data(start_date, end_date, @projects, params[:department])
  
    @timeline_data = collect_weeks_data(start_date, end_date, @projects, params[:department])

    timeline_result = collect_weeks_data(start_date, end_date, @projects, params[:department])
    @week_starts = timeline_result[:week_starts]
    @timeline_data = timeline_result[:timeline_data]

  end
  

  # GET /projects/1 or /projects/1.json
  def show
    @project = Project.find(params[:id]) #show specific Project by ID
    @comment = @project.comments.build #Prepares a new comment object for the form. Using .build creates a new, unsaved comment associated with the project, ready to be filled by the user. This is needed because the form for adding a new comment expects an empty @comment to render correctly.
    @comments = @project.comments.order(created_at: :desc) #show all comments associated with the project from newest to oldest
    @comments_by_date = @comments.group_by { |comment| comment.created_at.to_date } #group comments by created date
      
  # Calculate weeks from project start date to current date
    starting_date = @project.start_date.beginning_of_week #get the week's start date when the project began
    ending_date = Date.today.end_of_week #get the end of the current week.
    total_weeks = ((ending_date - starting_date) / 7).to_i #Calculate the number of weeks between the starting and ending dates.

    @weeks_data = (0..total_weeks).map do |i| #Generate an array of hashes containing the week start date and the count of comments for each week.
    week_start = starting_date + i.weeks
    week_end = week_start + 1.week
    comments_in_week = @project.comments.where(created_at: week_start...week_end)
    {
      week_start: week_start,
      count: comments_in_week.count
    }
    end
  end

  # GET /projects/new
  def new
    @project = Project.new
  end  

  # GET /projects/1/edit
  def edit
  end

  # POST /projects or /projects.json
  def create
    @project = current_user.projects.build(project_params)
    respond_to do |format|
      if @project.save
        format.turbo_stream do
          render turbo_stream: [
            turbo_stream.prepend("all-projects", partial: "projects/project_card", locals: { project: @project }),
            turbo_stream.remove("new_project_modal") # This removes the modal after success
          ]
        end
        format.html { redirect_to project_url(@project), notice: "Project was successfully created." }
        format.json { render :show, status: :created, location: @project }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @project.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /projects/1 or /projects/1.json
  def update
    respond_to do |format|
      if @project.update(project_params)
        format.html { redirect_to project_url(@project), notice: "Project was successfully updated." }
        format.json { render :show, status: :ok, location: @project }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @project.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /projects/1 or /projects/1.json
  def destroy
    @project.destroy!

    respond_to do |format|
      format.html { redirect_to projects_url, notice: "Project was successfully destroyed." }
      format.json { head :no_content }
    end
  end

  def weekly_comments
        # Logic to handle weekly comments
        week_start = params[:week_start]
        # Fetch comments based on the week_start parameter
        # Render the modal or page as needed
      end    

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_project
      @project = Project.find(params[:id])
    end

    # Only allow a list of trusted parameters through.
    def project_params
      params.require(:project).permit(:name, :description, :start_date, :end_date, :department)
    end

    def collect_weeks_data(start_date, end_date, projects, department)
  total_weeks = ((end_date - start_date).to_i / 7).ceil
  week_starts = (0..total_weeks).map { |i| start_date + i.weeks }

  timeline_data = []

  if department.present? && department != 'All Departments'
    # For a specific department, list projects
    projects_in_department = projects.where(department: department)
    projects_in_department.each do |project|
      project_data = {
        name: project.name,
        weeks: []
      }
      week_starts.each do |week_start|
        week_end = week_start + 1.week
        count = project.comments.where(created_at: week_start...week_end).count
        project_data[:weeks] << { week_start: week_start, count: count }
      end
      timeline_data << project_data
    end
  else
    # For all departments
    departments = projects.pluck(:department).uniq
    departments.each do |dept|
      dept_projects = projects.where(department: dept)
      dept_data = {
        name: dept,
        weeks: []
      }
      week_starts.each do |week_start|
        week_end = week_start + 1.week
        count = Comment.joins(:project)
                       .where(projects: { id: dept_projects.pluck(:id) })
                       .where(created_at: week_start...week_end)
                       .count
        dept_data[:weeks] << { week_start: week_start, count: count }
      end
      timeline_data << dept_data
    end
  end

  { week_starts: week_starts, timeline_data: timeline_data }
end

    
    
    
end

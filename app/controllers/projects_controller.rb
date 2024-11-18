class ProjectsController < ApplicationController
  before_action :authenticate_user!, except: [:index, :show] #checks if user is authenticated whenever they try to run any operation besides index and show
  before_action :set_project, only: %i[ show edit update destroy ]

  # GET /projects or /projects.json
  def index
    @projects = Project.all
    
    # Initialize start_date and end_date with existing date parsing logic
    start_date = parse_start_date(params[:start_date])
    end_date = parse_end_date(params[:end_date])

    # Use scopes to filter projects
    @projects = Project.by_department(params[:department]).by_date_range(start_date, end_date)

    # Proceed with timeline data collection
    total_weeks = ((end_date - start_date).to_i / 7).ceil
    week_starts = (0..total_weeks).map { |i| start_date + i.weeks }

    timeline_data = []

    if params[:department].present? && params[:department] != 'All Departments'
      @projects.each do |project|
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
      departments = @projects.pluck(:department).uniq
      departments.each do |dept|
        dept_projects = @projects.where(department: dept)
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

    @week_starts = week_starts
    @timeline_data = timeline_data

  end
  
  # GET /projects/1 or /projects/1.json
  def show
    @comment = @project.comments.build #Prepares a new comment object for the form. Using .build creates a new, unsaved comment associated with the project, ready to be filled by the user. This is needed because the form for adding a new comment expects an empty @comment to render correctly.
    @comments = @project.comments.order(created_at: :desc) #show all comments associated with the project from newest to oldest
    @comments_by_date = @comments.group_by { |comment| comment.created_at.to_date } #group comments by created date
      
    #Calculate weeks from project start date to current date
    starting_date = @project.start_date.beginning_of_week #Retrieves the start_date of the current project (@project) and adjusts it to the beginning of that week
    ending_date = Date.today.end_of_week #get the end of the current week.
    total_weeks = ((ending_date - starting_date) / 7).to_i #Subtracts the starting_date from the ending_date, giving the total number of days between them, divide it by 7 to calculate number of weeks and converts the result to integer (.to_i), rounding down if needed
    
    #Generate an array of hashes containing the week start date and the count of comments for each week.
    @weeks_data = (0..total_weeks).map do |i| #"do" is a chunk of code that you pass to a method to be executed for each element that the method operates on.".map" is a method that iterates over each element in the range (0..total_weeks) and executes the code inside the block for each element.
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

  private #methods defined below the "private" line are only accessible within the class itself (meaning they cannot be directly invoked as actions via a web request and we ensure this is only used internally and not accessible via a URL). These methods are implementation details used to support the public controller actions. Exposing these methods as actions would create unnecessary and potentially insecure entry points into your application.
    
    def set_project #Use callbacks to share common setup or constraints between actions.
      @project = Project.find(params[:id])
    end

    def project_params #defines the permitted parameters for a Project object. It ensures only safe and allowed attributes (e.g., :name, :description, etc.) can be passed to your model when creating or updating a project.
      params.require(:project).permit(:name, :description, :start_date, :end_date, :department)
    end 

    def parse_start_date(start_date_param)
      return 8.weeks.ago.beginning_of_week.to_date if start_date_param.blank?
      Date.parse(start_date_param).beginning_of_week.to_date
    rescue ArgumentError
      8.weeks.ago.beginning_of_week.to_date
    end
    
    def parse_end_date(end_date_param)
      return Date.today.end_of_week if end_date_param.blank?
      Date.parse(end_date_param).end_of_week.to_date
    rescue ArgumentError
      Date.today.end_of_week
    end   

end

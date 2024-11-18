class ProjectsController < ApplicationController
  before_action :authenticate_user!, except: [:index, :show] #checks if user is authenticated whenever they try to run any operation besides index and show
  before_action :set_project, only: %i[ show edit update destroy ]

  # GET /projects or /projects.json
  def index
    start_date = parse_start_date(params[:start_date])
    end_date = parse_end_date(params[:end_date])
  
    @projects = Project.by_department(params[:department]).by_date_range(start_date, end_date)
  
    total_weeks = ((end_date - start_date).to_i / 7).ceil
    week_starts = (0..total_weeks).map { |i| start_date + i.weeks }
  
    @timeline_data = ProjectsTimelineDataService.new(@projects, week_starts, params[:department]).call
    @week_starts = week_starts
  end
  
  # GET /projects/1 or /projects/1.json
  def show
    @comment = @project.comments.build
    @comments = @project.comments.order(created_at: :desc)
    @comments_by_date = @comments.group_by { |comment| comment.created_at.to_date }

    starting_date = @project.start_date.beginning_of_week
    ending_date = Date.today.end_of_week

    @weeks_data = CommentsTimelineDataService.new(@project, starting_date, ending_date).call
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

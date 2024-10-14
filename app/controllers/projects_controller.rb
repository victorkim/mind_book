class ProjectsController < ApplicationController
  before_action :authenticate_user!, except: [:index, :show] #checks if user is authenticated whenever they try to run any operation besides index and show
  before_action :set_project, only: %i[ show edit update destroy ]

  # GET /projects or /projects.json
  def index
    @projects = Project.all
    @recent_projects = Project.recent #self.recent is defined in the Model
    @due_soon_projects = Project.due_soon #self.due_soon is defined in the Model
    @past_due_projects = Project.past_due #self.past_due is defined in the Model
  end

  # GET /projects/1 or /projects/1.json
  def show
      @project = Project.find(params[:id])
      @comment = @project.comments.build
      @comments = @project.comments
      
      comments = @project.comments.order(:created_at) #Retrieves all comments for the project, ordered by their creation date (oldest to newest).

      @comment_data = comments.map.with_index do |comment, index| #Maps over the comments with their index to calculate the time gap between consecutive comments.
        previous_date = index.zero? ? nil : comments[index - 1].created_at.to_date #On the first iteration (index 0), there is no previous comment, so `previous_date` is nil. For subsequent iterations, `previous_date` is set to the created_at date of the previous comment.The "?" is basically a "if" statement. Also, "to_date" is a method that converts timestamps or any other date information into date-only
        days_gap = previous_date ? (comment.created_at.to_date - previous_date).to_i : 0  #Calculates the difference (days_gap) between the current comment’s date and the previous comment’s date. If there is no previous date (on the first comment), the gap is 0. The "to_i" method converts an object into an integer, so that math operations only have integer numbers
    
        { comment: comment, days_gap: days_gap } #Returns a hash containing the comment and its calculated days gap.
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

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_project
      @project = Project.find(params[:id])
    end

    # Only allow a list of trusted parameters through.
    def project_params
      params.require(:project).permit(:name, :description, :start_date, :end_date)
    end
    
end

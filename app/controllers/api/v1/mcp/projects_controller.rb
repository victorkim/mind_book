class Api::V1::Mcp::ProjectsController < ApplicationController
	# Skip CSRF protection for API endpoints
	skip_before_action :verify_authenticity_token
	
	before_action :set_project, only: [:show]
	
	# GET /api/v1/mcp/projects
	def index
		projects = Project.all
		render json: {
			status: 'success',
			data: projects.map { |project| project_json(project) }
		}
	end
	
	# GET /api/v1/mcp/projects/:id
	def show
		render json: {
			status: 'success',
			data: project_json(@project)
		}
	end
	
  # POST /api/v1/mcp/projects
  def create
    project = Project.new(project_params)
    
    if project.save
      render json: {
        status: 'success',
        message: 'Project created successfully',
        data: project_json(project)
      }, status: :created
    else
      render json: {
        status: 'error',
        message: 'Failed to create project',
        errors: project.errors.full_messages
      }, status: :unprocessable_entity
    end
  end

	private
	
	def set_project
		@project = Project.find(params[:id])
	rescue ActiveRecord::RecordNotFound
		render json: { status: 'error', message: 'Project not found' }, status: :not_found
	end
	
	def project_json(project)
		{
			id: project.id,
			name: project.name,
			description: project.description.to_s, # Convert rich text to string
			start_date: project.start_date,
			end_date: project.end_date,
			department: project.department,
			created_at: project.created_at,
			updated_at: project.updated_at
		}
	end
	
	# Override this method in ApplicationController if it doesn't exist
	def skip_auth?
		true # For now, we'll skip auth. You can add API tokens later.
	end

	def project_params
		params.permit(:name, :description, :start_date, :end_date, :department)
	end

end
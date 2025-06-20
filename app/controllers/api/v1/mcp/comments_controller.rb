class Api::V1::Mcp::CommentsController < ApplicationController
	# Skip CSRF protection for API endpoints
	skip_before_action :verify_authenticity_token
	
	before_action :set_channel, only: [:create]
	before_action :set_comment, only: [:destroy]
	
	# GET /api/v1/mcp/comments
	def index
		comments = Comment.includes(:project, :channel).all
		render json: {
			status: 'success',
			data: comments.map { |comment| comment_json(comment) }
		}
	end
	
	# POST /api/v1/mcp/channels/:channel_id/comments
	def create
		# Find the project by name (case-insensitive)
		project = Project.where('LOWER(name) = ?', params[:project_name].downcase).first
		
		unless project
			render json: { 
				status: 'error', 
				message: "Project '#{params[:project_name]}' not found" 
			}, status: :unprocessable_entity
			return
		end
		
		# Create the comment
		comment = Comment.new(
			body: params[:body],
			date: params[:date] || Date.today,
			channel: @channel,
			project: project,
			user: User.first # For now, use the first user. You can improve this later.
		)
		
		if comment.save
			render json: {
				status: 'success',
				message: 'Comment created successfully',
				data: comment_json(comment)
			}, status: :created
		else
			render json: {
				status: 'error',
				message: 'Failed to create comment',
				errors: comment.errors.full_messages
			}, status: :unprocessable_entity
		end
	end
	
  # DELETE /api/v1/mcp/comments/:id
  def destroy
    if @comment.destroy
      render json: {
        status: 'success',
        message: 'Comment deleted successfully'
      }
    else
      render json: {
        status: 'error',
        message: 'Failed to delete comment',
        errors: @comment.errors.full_messages
      }, status: :unprocessable_entity
    end
  end
  
  # DELETE /api/v1/mcp/comments/bulk_delete_demo
  def bulk_delete_demo
    # Delete comments associated with demo projects or channels
    deleted_count = Comment.joins(:project, :channel)
                          .where("projects.name ILIKE ? OR channels.name ILIKE ?", "%demo%", "%demo%")
                          .destroy_all.count
    render json: {
      status: 'success',
      message: "Deleted #{deleted_count} demo comments"
    }
  end

	private
	
	def set_comment
    @comment = Comment.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    render json: { status: 'error', message: 'Comment not found' }, status: :not_found
  end
	
	def set_channel
		@channel = Channel.find(params[:channel_id])
	rescue ActiveRecord::RecordNotFound
		render json: { status: 'error', message: 'Channel not found' }, status: :not_found
	end
	
	def comment_json(comment)
		{
			id: comment.id,
			body: comment.body.to_s, # Convert rich text to string
			date: comment.date,
			project_id: comment.project_id,
			project_name: comment.project&.name,
			channel_id: comment.channel_id,
			channel_name: comment.channel&.name,
			created_at: comment.created_at,
			updated_at: comment.updated_at
		}
	end
	
	# Override this method in ApplicationController if it doesn't exist
	def skip_auth?
		true # For now, we'll skip auth. You can add API tokens later.
	end
end
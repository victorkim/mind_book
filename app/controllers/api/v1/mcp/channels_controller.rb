class Api::V1::Mcp::ChannelsController < ApplicationController
	# Skip CSRF protection for API endpoints
	skip_before_action :verify_authenticity_token
	
	before_action :set_channel, only: [:show]
	
	# GET /api/v1/mcp/channels
	def index
		channels = Channel.all
		render json: {
			status: 'success',
			data: channels.map { |channel| channel_json(channel) }
		}
	end
	
	# GET /api/v1/mcp/channels/:id
	def show
		render json: {
			status: 'success',
			data: channel_json(@channel)
		}
	end

  # POST /api/v1/mcp/channels
  def create
    channel = Channel.new(channel_params)
    
    if channel.save
      render json: {
        status: 'success',
        message: 'Channel created successfully',
        data: channel_json(channel)
      }, status: :created
    else
      render json: {
        status: 'error',
        message: 'Failed to create channel',
        errors: channel.errors.full_messages
      }, status: :unprocessable_entity
    end
  end

	private
	
	def set_channel
		@channel = Channel.find(params[:id])
	rescue ActiveRecord::RecordNotFound
		render json: { status: 'error', message: 'Channel not found' }, status: :not_found
	end
	
	def channel_json(channel)
		{
			id: channel.id,
			name: channel.name,
			created_at: channel.created_at,
			updated_at: channel.updated_at
		}
	end
	
	# Override this method in ApplicationController if it doesn't exist
	def skip_auth?
		true # For now, we'll skip auth. You can add API tokens later.
	end

	def channel_params
		params.permit(:name)
	end

end
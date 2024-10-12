class ApplicationController < ActionController::Base
  
  def after_sign_in_path_for(resource) #Override Devise method to redirect after login
    stored_location_for(resource) || projects_path #Redirect to stored location or fallback to index
  end

  def after_sign_out_path_for(resource_or_scope) #Override Devise method to redirect after logout
    projects_path #Redirect to the projects index page after sign-out
  end

	private

  before_action :store_user_location!, if: :storable_location?

  def store_user_location! #Store the location to redirect the user after login
    store_location_for(:user, request.fullpath)
  end

end
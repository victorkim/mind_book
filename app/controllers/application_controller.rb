class ApplicationController < ActionController::Base
  before_action :store_user_location!, if: :storable_location?
  before_action :configure_permitted_parameters, if: :devise_controller?

  private

  def store_user_location! #Store the location to redirect the user back after login
    store_location_for(:user, request.fullpath)
  end

  def after_sign_in_path_for(resource) #Override Devise method to redirect the user after login
    stored_location_for(resource) || projects_path
  end

  def after_sign_out_path_for(resource_or_scope) #Override Devise method to redirect the user after logout
    projects_path
  end

  def storable_location? #Helper to determine if we should store the location
    request.get? && is_navigational_format? && !devise_controller? && !request.xhr?
  end

  def configure_permitted_parameters
    devise_parameter_sanitizer.permit(:sign_up, keys: [:name]) #This line allows the name field to be saved when a user signs up.
    devise_parameter_sanitizer.permit(:account_update, keys: [:name]) #This line allows the name field to be updated when a user edits their profile.
  end
end
class ApplicationController < ActionController::Base
  before_action :store_user_location!, if: :storable_location?

  private

  # Store the location to redirect the user back after login
  def store_user_location!
    store_location_for(:user, request.fullpath)
  end

  # Override Devise method to redirect the user after login
  def after_sign_in_path_for(resource)
    stored_location_for(resource) || projects_path
  end

  # Override Devise method to redirect the user after logout
  def after_sign_out_path_for(resource_or_scope)
    projects_path
  end

  # Helper to determine if we should store the location
  def storable_location?
    request.get? && is_navigational_format? && !devise_controller? && !request.xhr?
  end
end

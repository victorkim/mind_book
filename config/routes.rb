Rails.application.routes.draw do

  devise_for :users # Generates sign up, login, profile editing links in one single command

  root 'pages#home'
  get 'about', to: 'pages#about'
  get 'blog', to: 'pages#blog'
  get 'features', to: 'pages#features'
  get 'pricing', to: 'pages#pricing'
  
  resources :projects do
    resources :comments, only: [:index, :create, :edit, :update, :destroy] do
      collection do
        get 'weekly', to: 'comments#weekly', as: 'weekly' # Existing route
      end
    end
  end

  # Add the new route with a different name
  get 'projects/weekly_comments_overview', to: 'projects#weekly_comments', as: 'weekly_comments_overview'

  # Other routes...
end

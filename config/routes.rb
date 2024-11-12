Rails.application.routes.draw do

  devise_for :users #generates sign up, logins, profile editing links in one single command

  root 'pages#home'
  get 'about', to: 'pages#about'
  get 'blog', to: 'pages#blog'
  get 'features', to: 'pages#features'
  get 'pricing', to: 'pages#pricing'
  
  resources :projects do
    resources :comments, only: [:index, :create, :edit, :update, :destroy] do
      collection do
        get 'weekly', to: 'comments#weekly', as: 'weekly' #Creates a route for weekly_project_comments_path to map to the weekly action in CommentsController
      end
    end
  end
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Defines the root path route ("/")
  # root "posts#index"
end

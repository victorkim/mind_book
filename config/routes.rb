Rails.application.routes.draw do

  devise_for :users #generates sign up, logins, profile editing links in one single command

  root 'pages#home'
  get 'about', to: 'pages#about'
  get 'blog', to: 'pages#blog'
  get 'features', to: 'pages#features'
  get 'pricing', to: 'pages#pricing'
  
  resources :projects do #You are nesting the comments routes under projects, which means that all comment routes will be scoped to a specific project (e.g ,/projects/:project_id/comments).
      resources :comments, only: [:index, :create, :edit, :update, :destroy] #You're specifying the actions for comments.
  end
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Defines the root path route ("/")
  # root "posts#index"
end

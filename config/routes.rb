Rails.application.routes.draw do

  devise_for :users #Generates sign up, login, profile editing links in one single command with devise gem

  root 'pages#home' #Defining landing page of the website
  get 'about', to: 'pages#about'
  get 'blog', to: 'pages#blog'
  get 'features', to: 'pages#features'
  get 'pricing', to: 'pages#pricing'
  
  resources :projects do #RESTful routes for the Project model. Generates standard routes for all CRUD actions (resources helper is a shorthand for defining all the standard RESTful routes Rails expects)
    resources :comments, only: [:index, :create, :edit, :update, :destroy] do #Nesting comments under projects indicates that comments belong to a specific project (example route: projects/project_id/comments). Generates routes for comments that are associated with a project, but limits them to specific actions using only (new and show actions are excluded)
      collection do #Adds a custom route on the collection of comments, not tied to a specific comment ID. Usually used when you want to perform an action on a group of resources or fetch data for the entire collection
        get 'weekly', to: 'comments#weekly', as: 'weekly' #Defines a route to access weekly comments for a specific project mapped to the Weekly Actions in the Comments Controller
      end
    end
  end

  get 'projects/weekly_comments_overview', to: 'projects#weekly_comments', as: 'weekly_comments_overview' #Defines a standalone route outside of the nested resource and maps the URL /projects/weekly_comments_overview to the weekly_comments action in the ProjectsController.

end

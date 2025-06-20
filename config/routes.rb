Rails.application.routes.draw do
  devise_for :users
  
  root 'pages#home'
  get 'about', to: 'pages#about'
  get 'blog', to: 'pages#blog'
  get 'features', to: 'pages#features'
  get 'pricing', to: 'pages#pricing'
  
  resources :channels do
    resources :comments, only: [:create, :edit, :update, :destroy]
  end
  
  resources :projects do
    resources :comments, only: [:index, :create, :edit, :update, :destroy] do
      collection do
        get 'weekly', to: 'comments#weekly', as: 'weekly'
      end
    end
  end

  get 'projects/weekly_comments_overview', to: 'projects#weekly_comments', as: 'weekly_comments_overview'

  # Weekly Summaries Routes - UPDATED
  get 'weekly_summaries/:week_start', to: 'weekly_summaries#show', as: 'weekly_summary'
  get 'projects/:project_id/weekly_summaries/:week_start', to: 'weekly_summaries#show', as: 'project_weekly_summary'
  post 'weekly_summaries/batch_update/:week_start', to: 'weekly_summaries#batch_update', as: 'batch_update_weekly_summaries'
  post 'weekly_summaries/project_update/:project_id/:week_start', to: 'weekly_summaries#update_project_summary', as: 'update_project_weekly_summary'

   # Add these API routes for MCP
   namespace :api do
    namespace :v1 do
      namespace :mcp do
        resources :channels, only: [:index, :show, :create, :destroy] do
          resources :comments, only: [:create]
          collection do
            delete :bulk_delete_demo
          end
        end
        resources :projects, only: [:index, :show, :create, :destroy] do
          collection do
            delete :bulk_delete_demo
          end
        end
        resources :comments, only: [:index, :destroy] do
          collection do
            delete :bulk_delete_demo
          end
        end
      end
    end
  end 

end
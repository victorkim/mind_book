class WeeklySummariesController < ApplicationController
  before_action :authenticate_user!, except: [:show]
  
  def show
    @week_start = Date.parse(params[:week_start])
    @project = params[:project_id].present? ? Project.find(params[:project_id]) : nil
    
    if @project.nil?
      # Global view (projects index page) - editable project summaries
      @global_summary = WeeklySummary.for_week(@week_start)
      
      # Get all project summaries, including empty ones for new projects
      @project_summaries = WeeklySummary.all_project_summaries_for_week(@week_start)
      
      respond_to do |format|
        format.turbo_stream {
          render partial: 'weekly_summaries/batch_edit_form', 
                 locals: { 
                   global_summary: @global_summary, 
                   project_summaries: @project_summaries,
                   week_start: @week_start
                 }
        }
        format.html {
          render partial: 'weekly_summaries/batch_edit_form', 
                 locals: { 
                   global_summary: @global_summary, 
                   project_summaries: @project_summaries,
                   week_start: @week_start
                 }
        }
      end
    else
      # Project show page - editable project-specific summary
      @global_summary = WeeklySummary.for_week(@week_start)
      @project_summary = WeeklySummary.for_week(@week_start, @project)
      
      respond_to do |format|
        format.turbo_stream {
          render partial: 'weekly_summaries/project_edit_form', 
                 locals: { 
                   project: @project,
                   project_summary: @project_summary,
                   week_start: @week_start
                 }
        }
        format.html {
          render partial: 'weekly_summaries/project_edit_form', 
                 locals: { 
                   project: @project,
                   project_summary: @project_summary,
                   week_start: @week_start
                 }
        }
      end
    end
  end
  
  def batch_update
    @week_start = Date.parse(params[:week_start])
    
    # Update or create the global summary
    global_params = params[:global_summary]
    if global_params.present?
      global_summary = WeeklySummary.for_week(@week_start)
      global_summary.content = global_params[:content]
      global_summary.save
    end
    
    # Update or create each project summary
    if params[:project_summaries].present?
      params[:project_summaries].each do |project_id, summary_params|
        next if summary_params[:content].blank?
        
        project = Project.find(project_id)
        project_summary = WeeklySummary.for_week(@week_start, project)
        project_summary.content = summary_params[:content]
        project_summary.save
      end
    end
    
    redirect_back(fallback_location: projects_path, notice: 'Weekly summaries were successfully updated.')
  end
  
  def update_project_summary
    @week_start = Date.parse(params[:week_start])
    @project = Project.find(params[:project_id])
    
    # Update the project summary
    project_params = params[:project_summary]
    if project_params.present?
      project_summary = WeeklySummary.for_week(@week_start, @project)
      project_summary.content = project_params[:content]
      project_summary.save
    end
    
    redirect_back(fallback_location: project_path(@project), notice: 'Weekly summary was successfully updated.')
  end
end
# in app/models/weekly_summary.rb
class WeeklySummary < ApplicationRecord
  belongs_to :project, optional: true
  
  validates :week_start, presence: true
  validates :week_start, uniqueness: { scope: :project_id }
  
  has_rich_text :content
  
  # Scope to get global summaries (not attached to any project)
  scope :global, -> { where(project_id: nil) }
  
  # Find or initialize a summary for a specific week and project context
  def self.for_week(week_start, project = nil)
    where(week_start: week_start, project: project).first_or_initialize
  end
  
  # Get all project summaries for a week, creating empty ones for projects without summaries
  def self.all_project_summaries_for_week(week_start)
    summaries = {}
    
    # Get all existing summaries for this week
    existing_summaries = where(week_start: week_start).where.not(project_id: nil)
    existing_project_ids = existing_summaries.pluck(:project_id)
    
    # Create a hash of project_id => summary
    existing_summaries.each do |summary|
      summaries[summary.project_id] = summary
    end
    
    # Add empty summaries for projects without existing summaries
    Project.where.not(id: existing_project_ids).each do |project|
      summaries[project.id] = for_week(week_start, project)
    end
    
    summaries
  end
end
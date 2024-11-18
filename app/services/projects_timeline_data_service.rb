class ProjectsTimelineDataService
  def initialize(projects, week_starts, department)
    @projects = projects
    @week_starts = week_starts
    @department = department
  end

  def call
    if department_present?
      projects_timeline
    else
      departments_timeline
    end
  end

  private

  attr_reader :projects, :week_starts, :department

  def department_present?
    department.present? && department != 'All Departments'
  end

  def projects_timeline
    projects.map do |project|
      {
        name: project.name,
        weeks: week_starts.map { |ws| { week_start: ws, count: count_comments(project.comments, ws) } }
      }
    end
  end

  def departments_timeline
    departments = projects.pluck(:department).uniq
    departments.map do |dept|
      dept_projects = projects.where(department: dept)
      {
        name: dept,
        weeks: week_starts.map { |ws| { week_start: ws, count: count_comments(Comment.where(project_id: dept_projects.ids), ws) } }
      }
    end
  end

  def count_comments(comments_scope, week_start)
    week_end = week_start + 1.week
    comments_scope.where(created_at: week_start...week_end).count
  end
end

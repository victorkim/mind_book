class ProjectsTimelineDataService
  
  def initialize(params) #constructor method initializes the service with projects, week start dates, and department filter
    @department = params[:department] #Assigns the department filter from params to an instance variable
    @start_date = parse_start_date(params[:start_date]) #Parses and assigns the start date from param
    @end_date = parse_end_date(params[:end_date]) #Parses and assigns the end date from param
  end

  def call #Public method to execute the service's main functionality
    
    @projects = Project.all

    # Apply department filtering unless "All" is selected
    @projects = @projects.where(department: @department) if department_present?
  
    # Apply date range filtering
    @projects = @projects.by_date_range(@start_date, @end_date)
    
    total_weeks = ((@end_date - @start_date).to_i / 7).ceil #Calculates the total number of weeks between start_date and end_date
    @week_starts = (0..total_weeks).map { |i| @start_date + i.weeks } #Generates an array of week start dates based on the total number of weeks

    timeline_data = department_present? ? projects_timeline : departments_timeline #Determines which timeline data to generate based on department presence
      {#Returns a hash containing :projects, :timeline_data, and :week_starts for the controller to use.
        projects: @projects, #Returns filtered projects as instance variable (@projects), because it's being defined above
        week_starts: @week_starts, #Generated as an array of week start dates from the start date as instance variable (@week_starts), because it's being defined above
        timeline_data: timeline_data #Local variable holding the generated timeline information
      }
  end

  private

  attr_reader :projects, :week_starts, :department  #Creates getter methods for the instance variables

  def parse_start_date(start_date_param) #Parse and return the start date; default to 8 weeks ago if invalid or blank
    return 8.weeks.ago.beginning_of_week.to_date if start_date_param.blank?
    Date.parse(start_date_param).beginning_of_week.to_date
  rescue ArgumentError
    8.weeks.ago.beginning_of_week.to_date
  end
  
  def parse_end_date(end_date_param) #Parse and return the end date; default to today if invalid or blank
    return Date.today.end_of_week if end_date_param.blank?
    Date.parse(end_date_param).end_of_week.to_date
  rescue ArgumentError
    Date.today.end_of_week
  end   
  
  def department_present? #Checks if a specific department filter is applied and valid
    department.present? && department != 'All'
  end

  def projects_timeline #Generates timeline aggregated data for each project
    projects.map do |project|
      {
        name: project.name,
        start_date: project.start_date,
        end_date: project.end_date,
        weeks: week_starts.map { |ws| { week_start: ws, count: count_comments(project.comments, ws) } }
      }
    end
  end

  def departments_timeline #Generates timeline aggregated data for each department
    departments = projects.pluck(:department).uniq
    departments.map do |dept|
      dept_projects = projects.where(department: dept)
      {
        name: dept,
        weeks: week_starts.map { |ws| { week_start: ws, count: count_comments(Comment.where(project_id: dept_projects.ids), ws) } }
      }
    end
  end

  def count_comments(comments_scope, week_start) #Counts the number of comments within a specific week
    week_end = week_start + 1.week
    comments_scope.where(created_at: week_start...week_end).count
  end
end

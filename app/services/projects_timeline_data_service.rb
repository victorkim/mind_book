class ProjectsTimelineDataService
  attr_reader :projects, :week_starts

  def initialize(params)
    @start_date_param = params[:start_date]
  end

  def call
    # 1) Always start from the beginning of the year
    current_year = Date.today.year
    @start_date = Date.new(current_year, 1, 1).beginning_of_week(:sunday)
    @end_date = Date.new(current_year, 12, 31).end_of_week(:saturday)

    # 2) Basic validation
    raise 'Invalid date range' if @start_date.nil? || @start_date > @end_date

    # 3) Load all projects
    @projects = Project.all

    # 4) Build an array of weeks from @start_date to @end_date
    total_weeks = ((@end_date - @start_date).to_i / 7).ceil
    @week_starts = (0..total_weeks).map { |i| @start_date + i.weeks }

    # 5) Build timeline data (comments per project per week)
    timeline_data = projects_timeline

    # 6) Return a hash of relevant data for the controller/view
    {
      projects: @projects,
      week_starts: @week_starts,
      timeline_data: timeline_data
    }
  end

  private

  def parse_date(date_str)
    Date.parse(date_str)
  rescue ArgumentError
    # If parsing fails, fallback to nil so the code uses earliest or default
    nil
  end

  def projects_timeline
    projects.map do |project|
      {
        name:       project.name,
        department: project.department,
        start_date: project.start_date,
        end_date:   project.end_date,
        weeks:      week_starts.map do |ws|
          { week_start: ws, count: count_comments(project.comments, ws) }
        end
      }
    end
  end

  def count_comments(comments_scope, week_start)
    week_end = week_start + 1.week
    comments_scope.where(date: week_start...week_end).count
  end
end
class ProjectsTimelineDataService
  attr_reader :projects, :week_starts

  def initialize(params)
    @start_date_param = params[:start_date]
  end

  def call
    # 1) Decide our overall start_date
    @start_date = calculate_start_date
    @end_date   = Date.today.end_of_week(:saturday)

    # 2) Basic validation
    raise 'Invalid date range' if @start_date.nil? || @start_date > @end_date

    # 3) Load all projects in the date range
    @projects = Project.by_date_range(@start_date, @end_date)

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

  def calculate_start_date
    # 1) If a param was given, parse it.
    return parse_date(@start_date_param).beginning_of_week(:sunday) if @start_date_param.present?

    # 2) Otherwise, find the earliest start_date across all projects in the DB.
    earliest = Project.minimum(:start_date)

    # 3) Use earliest if present, otherwise fallback to 8 weeks ago.
    (earliest || 8.weeks.ago).beginning_of_week(:sunday)
  end

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

class TimelineDataService
    attr_reader :items, :week_starts, :type
  
    # Initialize with either:
    # - type: :projects, items: Project.all (for project index page)
    # - type: :comments, items: @project (for project show page)
    # - optional params for filtering
    def initialize(options = {})
      @type = options[:type] || :projects
      @items = options[:items]
      @params = options[:params] || {}
      
      calculate_date_range
    end
  
    def call
      if @type == :projects
        return projects_timeline_data
      else
        return comments_timeline_data
      end
    end
  
    private
  
    def calculate_date_range
      if @type == :projects
        # For projects timeline - use current year
        current_year = Date.today.year
        @start_date = Date.new(current_year, 1, 1).beginning_of_week(:sunday)
        @end_date = Date.new(current_year, 12, 31).end_of_week(:saturday)
      else
        # For comments timeline - use parent's dates
        parent = @items
        
        # If the parent has a start_date, use it. Otherwise, use created_at.
        if parent.respond_to?(:start_date) && parent.start_date.present?
          @start_date = parent.start_date.to_date.beginning_of_week(:sunday)
        else
          @start_date = parent.created_at.to_date.beginning_of_week(:sunday)
        end
        
        # Use the project's end_date instead of today's date if available
        if parent.respond_to?(:end_date) && parent.end_date.present?
          @end_date = parent.end_date.to_date.end_of_week(:saturday)
        else
          @end_date = Date.today.end_of_week(:saturday)
        end
      end
  
      # Basic validation
      raise 'Invalid date range' if @start_date.nil? || @start_date > @end_date
      
      # Calculate weeks between start and end date
      total_weeks = ((@end_date - @start_date).to_i / 7).ceil
      @week_starts = (0..total_weeks).map { |i| @start_date + i.weeks }
    end
  
    def projects_timeline_data
      # Return structure expected by the projects timeline view
      {
        projects: @items,
        week_starts: @week_starts,
        timeline_data: generate_projects_timeline_data
      }
    end
  
    def comments_timeline_data
      # Return structure expected by the comments timeline view
      @week_starts.map do |week_start|
        {
          week_start: week_start,
          count: @items.comments.where(date: week_start...week_start + 7).count
        }
      end
    end
  
    def generate_projects_timeline_data
      @items.map do |project|
        {
          name: project.name,
          department: project.department,
          start_date: project.start_date,
          end_date: project.end_date,
          weeks: @week_starts.map do |ws|
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
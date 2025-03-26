class CommentsTimelineDataService
  def initialize(parent)
    @parent = parent
    # If the parent has a start_date, use it (converted to a Date). Otherwise, use created_at (converted to Date).
    if @parent.respond_to?(:start_date) && @parent.start_date.present?
      @starting_date = @parent.start_date.to_date.beginning_of_week(:sunday)
    else
      @starting_date = @parent.created_at.to_date.beginning_of_week(:sunday)
    end
    
    # Use the project's end_date instead of today's date if available
    if @parent.respond_to?(:end_date) && @parent.end_date.present?
      @ending_date = @parent.end_date.to_date.end_of_week(:saturday)
    else
      @ending_date = Date.today.end_of_week(:saturday)
    end
  end

  def call
    weeks = calculate_weeks
    weeks.map do |week_start|
      {
        week_start: week_start,
        count: @parent.comments.where(date: week_start...week_start + 7).count
      }
    end
  end

  private

  def calculate_weeks
    total_weeks = ((@ending_date - @starting_date) / 7).to_i
    (0..total_weeks).map { |i| @starting_date + (i * 7) }
  end
end
class CommentsTimelineDataService
	def initialize(project, starting_date, ending_date)
		@project = project
		@starting_date = starting_date
		@ending_date = ending_date
	end

	def call
		weeks = calculate_weeks
		weeks.map do |week_start|
			{
				week_start: week_start,
				count: @project.comments.where(created_at: week_start...week_start + 1.week).count
			}
		end
	end

	private

	def calculate_weeks
		total_weeks = ((@ending_date - @starting_date) / 7).to_i
		(0..total_weeks).map { |i| @starting_date + i.weeks }
	end
end

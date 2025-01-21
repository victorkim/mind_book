class CommentsTimelineDataService

	def initialize(project) #Using the project object as parameter for which the comment timeline is being generated. This service is tightly coupled to a specific project. It needs access to the start_date of the project and its associated comments to generate a timeline.
		@project = project #Assigns @project to an instance variable for use in other methods. The @project instance variable provides direct access to the project's attributes
		@starting_date = project.start_date.beginning_of_week(:sunday) #Calculate starting date here (weeks starting on a sunday)
		@ending_date = Date.today.end_of_week(:saturday) #Calculate ending date here (weeks ending on a saturday)
	end

	def call
		weeks = calculate_weeks #generates an array of week start dates between @starting_date and @ending_date.
		weeks.map do |week_start|
			{
				week_start: week_start,
				count: @project.comments.where(date: week_start...week_start + 1.week).count
			}
		end
	end

	private

	def calculate_weeks
		total_weeks = ((@ending_date - @starting_date) / 7).to_i #Calculate total weeks in the date range
		(0..total_weeks).map { |i| @starting_date + i.weeks } #Generate array of week start dates
	end
end

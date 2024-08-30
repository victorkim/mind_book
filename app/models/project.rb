class Project < ApplicationRecord
    validates :name, presence: true
    has_rich_text :description
    validates :start_date, presence: true
    validates :end_date, presence: true

    def self.recent #defining a method that encapsulates projects created in the last 5 days
        where('created_at >= ?', 5.days.ago) #limiting to 1 record for testing purposes
    end

    def self.due_soon #defining a method that encapsulates projects with end date in the next 7 days
        where(end_date: Date.today..365.days.from_now) #limiting to 1 record for testing purposes
    end      
end

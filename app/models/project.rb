class Project < ApplicationRecord
    validates :name, presence: true
    validates :start_date, presence: true
    validates :end_date, presence: true
    has_rich_text :description

    def self.recent #defining a method that encapsulates projects created in the last 5 days
        where('created_at >= ?', 15.days.ago)
    end

    def self.due_soon #defining a method that encapsulates projects with end date in the next 365 days
        where(end_date: Date.today..365.days.from_now)
    end

    def self.past_due #defining a method that encapsulates projects with end date in the next 7 days
        where('end_date < ?', Date.today)
    end

end

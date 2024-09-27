class Project < ApplicationRecord
    belongs_to :user, optional: true #adds a validation that every project needs an user and adds a user_id column in the projects table. however, the "option: true" allows user_id to be NULL in case the current user of a project is deleted because of the "dependent: :nullify" criteria in the user model
    has_many :comments, dependent: :destroy #make sure to add the inverse association in the comments model. also, "dependent: :destroy" makes sure that all associated comments will be deleted once the project is
    
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

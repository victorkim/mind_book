class Project < ApplicationRecord
	belongs_to :user, optional: true #adds a validation that every project needs an user and adds a user_id column in the projects table. however, the "option: true" allows user_id to be NULL in case the current user of a project is deleted because of the "dependent: :nullify" criteria in the user model
	has_many :comments, dependent: :destroy #make sure to add the inverse association in the comments model. also, "dependent: :destroy" makes sure that all associated comments will be deleted once the project is
	
	validates :name, presence: true
	validates :start_date, presence: true
	validates :end_date, presence: true
	validates :department, presence: true
	has_rich_text :description

	scope :by_department, ->(department) { where(department: department) if department.present? }
  	scope :by_date_range, ->(start_date, end_date) { where(start_date: start_date..end_date) }

end

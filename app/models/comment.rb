class Comment < ApplicationRecord
  belongs_to :user, optional: true #adds a validation that every comment needs an user and adds a user_id column in the comment table. however, the "option: true" allows user_id to be NULL in case the current user of a comment is deleted because of the "dependent: :nullify" criteria in the user model
  belongs_to :project, optional: false #project must exist (check project model "has_many :comments, dependent: :destroy")

  validates :body, presence: true
  validates :date, presence: true
end

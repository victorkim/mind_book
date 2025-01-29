class Channel < ApplicationRecord
    belongs_to :user, optional: true
    has_many :comments, dependent: :nullify # A channel can have many comments
end  
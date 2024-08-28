class Project < ApplicationRecord
    validates :name, presence: true
    has_rich_text :description
    validates :start_date, presence: true
    validates :end_date, presence: true    
end

class Project < ApplicationRecord
    validates_presence_of :name
    has_rich_text :description
end

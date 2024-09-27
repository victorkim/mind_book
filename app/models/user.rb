class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable
  
  has_many :projects, dependent: :nullify #makes sure that projects won't be deleted if/when the associated user is. the associated user_id will be set to NULL instead
  has_many :comments, dependent: :nullify #makes sure that comments won't be deleted if/when the associated user is. the associated user_id will be set to NULL instead
end

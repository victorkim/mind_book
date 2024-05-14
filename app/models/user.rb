# email:string
# password_digest:string
# password: string -> virtual attribute?
# password_confirmation: string -> virtual attribute

class User < ApplicationRecord
    has_secure_password

    validates :email, presence: true
    normalizes :email, with: -> (email) {email.strip.downcase} #normalizes the email, stripping blanks and downcasing everythin
end

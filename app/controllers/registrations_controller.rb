class RegistrationsController < ApplicationController
    
    def new #used to create a new user
        @user = User.new
    end

    def create #used to save a new user to the database
        @user = User.new(user_params) #this will assign all the user params (email, password and password confirmation) to the new user in the database
        if @user.save
            redirect_to root_path, notice: "You've successfully created your account!" #if user is created, redirect to home page with notice
        else
            render :new, status: :unprocessable_entity #otherwise, it will render the new.html.erb view under the registrations folder
        end
    end

    private #methods defined after the private keyword cannot be called as public actions. They are only available within the context of the controller itself, not from outside via a URL route.

    def user_params
        params.require(:user).permit(:email, :password, :password_confirmation) #allows only email, password and password confirmation to be set by user
    end

end
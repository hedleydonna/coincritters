class ApplicationController < ActionController::Base
    protect_from_forgery with: :exception
  
    before_action :authenticate_user!
  
    # Allow public splash page
    (only the home index action)
    skip_before_action :authenticate_user!, only: :index, controller: :home
  
    # Allow all Devise actions (login, signup, etc.)
    skip_before_action :authenticate_user!, if: :devise_controller?
  end
  
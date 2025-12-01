class ApplicationController < ActionController::Base
    protect_from_forgery with: :exception
  
    # Require login for all actions
    before_action :authenticate_user!
  
    # Allow public splash page without login
    skip_before_action :authenticate_user!, only: :index, controller: :home
  
    # Allow Devise controllers (sign up, log in, etc.) without forcing login
    skip_before_action :authenticate_user!, if: :devise_controller?
  end
  
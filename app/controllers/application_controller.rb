class ApplicationController < ActionController::Base
    protect_from_forgery with: :exception
  
    # DO NOT require login on Devise controllers
    before_action :authenticate_user!, except: [] # we handle skips below
  
    # Allow Devise controllers (login, signup, etc.)
    skip_before_action :authenticate_user!, if: :devise_controller?
  
    # Allow the public splash page
    skip_before_action :authenticate_user!, only: :index, if: -> { controller_name == "home" && action_name == "index" }
  end
  
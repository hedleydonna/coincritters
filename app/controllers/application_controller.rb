class ApplicationController < ActionController::Base
    protect_from_forgery with: :exception
  
    # Skip authentication for Devise controllers AND the splash page
    before_action :authenticate_user!, unless: :devise_or_home_controller?
  
    private
  
    def devise_or_home_controller?
      devise_controller? || (controller_name == "home" && action_name == "index")
    end
  end
  
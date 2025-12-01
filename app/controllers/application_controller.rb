class ApplicationController < ActionController::Base
    protect_from_forgery with: :exception
  
    # Only skip auth for Devise and home splash
    before_action :authenticate_user!, unless: -> {
      devise_controller? || (controller_name == "home" && action_name == "index")
    }
  end
  
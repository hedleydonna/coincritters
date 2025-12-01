class ApplicationController < ActionController::Base
    protect_from_forgery with: :exception
  
    # Require login for everything
    before_action :authenticate_user!
  
    # BUT allow the public splash page without login
    skip_before_action :authenticate_user!, if: :devise_controller?
    skip_before_action :authenticate_user!, only: :index, controller: :home
  end
  
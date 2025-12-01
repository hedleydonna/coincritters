class ApplicationController < ActionController::Base
    protect_from_forgery with: :exception
  
    # Require login for EVERYTHING
    before_action :authenticate_user!
  
    # BUT allow these without login:
    # 1. The public splash page
    skip_before_action :authenticate_user!, only: :index, controller: :home
  
    # 2. ALL Devise controllers (sign-up, login, etc.)
    skip_before_action :authenticate_user!, if: :devise_controller?
  end
  
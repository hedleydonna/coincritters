class ApplicationController < ActionController::Base
    protect_from_forgery with: :exception
  
    # This single line is the magic that makes login go to dashboard instead of root
    def after_sign_in_path_for(resource)
      dashboard_path
    end
  end
  

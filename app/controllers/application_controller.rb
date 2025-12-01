# app/controllers/application_controller.rb
class ApplicationController < ActionController::Base
    protected
  
    def after_sign_in_path_for(resource)
      dashboard_path   # ← THIS LINE IS REQUIRED
    end
  end
  
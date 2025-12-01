class ApplicationController < ActionController::Base
    protect_from_forgery with: :exception
  
    # This forces every controller to require login…
    before_action :authenticate_user!
  
    # …except the public splash page
    skip_before_action :authenticate_user!, only: [:index], controller: :home
  end
  
class ApplicationController < ActionController::Base
    protect_from_forgery with: :exception
  
    # This is the magic line — makes Devise sign in the user immediately after sign-up
    before_action :authenticate_user!, except: [:index]
  end
  
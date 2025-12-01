Rails.application.routes.draw do
  devise_for :users
  
  # Public routes
  get "up" => "rails/health#show", as: :rails_health_check
  root "home#index"
  
  # Authenticated routes
  get "dashboard", to: "dashboard#index"
end

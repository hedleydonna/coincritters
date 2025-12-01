Rails.application.routes.draw do
  devise_for :users

  # Public splash page
  root to: "home#index"

  # THIS IS THE LINE THAT ACTUALLY SENDS LOGGED-IN USERS TO DASHBOARD
  authenticated :user do
    root "dashboard#index", as: :authenticated_root
  end

  # Direct access to dashboard
  get "/dashboard", to: "dashboard#index"

  get "up" => "rails/health#show", as: :rails_health_check
end

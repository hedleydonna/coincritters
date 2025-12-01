Rails.application.routes.draw do
  devise_for :users

  # Public routes
  root "home#index"
  get "up" => "rails/health#show", as: :rails_health_check

  # Authenticated routes
  authenticated :user do
    root "dashboard#index", as: :authenticated_root
  end

  # Optional: you can still reach /dashboard directly if you want
  get "dashboard", to: "dashboard#index"
end

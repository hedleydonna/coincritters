Rails.application.routes.draw do
  devise_for :users

  # Unauthenticated users → beautiful public landing page (Home#index)
  root to: "home#index"

  # Authenticated users → dashboard
  authenticated :user do
    root to: "dashboard#index", as: :authenticated_root
  end

  # Health check
  get "up" => "rails/health#show", as: :rails_health_check

  # Optional direct access
  get "dashboard", to: "dashboard#index"
end

Rails.application.routes.draw do
  devise_for :users

  # Public landing page (for guests)
  root to: "home#index"

  # This is the KEY line — forces logged-in users straight to dashboard
  authenticated :user do
    root to: "dashboard#index", as: :authenticated_root
  end

  # Optional: you can still visit /dashboard directly
  get "dashboard", to: "dashboard#index"

  # Health check
  get "up" => "rails/health#show", as: :rails_health_check
end

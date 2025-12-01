Rails.application.routes.draw do
  devise_for :users

  # Public splash page
  root to: "home#index"

  # Logged-in users go straight to dashboard
  authenticated :user do
    root "dashboard#index", as: :authenticated_root
  end

  get "dashboard", to: "dashboard#index"
  get "up" => "rails/health#show", as: :rails_health_check
end

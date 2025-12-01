Rails.application.routes.draw do
  devise_for :users

  # ←←← THIS LINE IS THE KEY ←←←
  unauthenticated do
    root "devise/sessions#new", as: :unauthenticated_root
  end

  # Public routes
  get "up" => "rails/health#show", as: :rails_health_check

  # Authenticated users go straight to dashboard
  authenticated :user do
    root "dashboard#index", as: :authenticated_root
  end

  get "dashboard", to: "dashboard#index"
end

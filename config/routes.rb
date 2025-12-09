Rails.application.routes.draw do
  devise_for :users, controllers: {
    registrations: 'users/registrations'
  }

  # Public splash page
  root to: "home#index"

  # THIS LINE IS THE ONLY THING THAT MATTERS
  authenticated :user do
    root "dashboard#index", as: :authenticated_root
  end

  get "dashboard", to: "dashboard#index"
  get "up" => "rails/health#show", as: :rails_health_check
end

Rails.application.routes.draw do
  devise_for :users

  # Public splash page for guests
  root to: "home#index"

  # THIS LINE IS THE ONE THAT WAS BROKEN BEFORE – comma fixed
  authenticated :user do
    root "dashboard#index", as: :authenticated_root
  end

  # Optional direct access
  get "dashboard", to: "dashboard#index"

  get "up" => "rails/health#show", as: :rails_health_check
end

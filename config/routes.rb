Rails.application.routes.draw do
  devise_for :users

  root to: "home#index"

  authenticated :user do
    root "dashboard#index", as: :authenticated_root
  end

  get "dashboard", to: "dashboard#index"
  get "up" => "rails/health#show", as: :rails_health_check
end

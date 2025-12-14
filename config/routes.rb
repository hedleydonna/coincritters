Rails.application.routes.draw do
  get 'static/credits'
  devise_for :users, controllers: {
    registrations: 'users/registrations'
  }

  # Public splash page
  root to: "home#index"

  # THIS LINE IS THE ONLY THING THAT MATTERS
  authenticated :user do
    root "dashboard#index", as: :authenticated_root
    
    resources :expense_templates, except: [:show] do
      member do
        patch :reactivate
      end
    end
    
    get "expenses", to: "expenses#index"
    resources :payments, only: [:new, :create]
    resources :expenses, only: [:new, :create]
  end

  get "dashboard", to: "dashboard#index"
  get "up" => "rails/health#show", as: :rails_health_check

  get "/credits", to: "static#credits", as: :credits

  # Admin routes
  namespace :admin do
    root "dashboard#index"
    resources :users
    resources :incomes
    resources :income_events
    resources :monthly_budgets
    resources :expense_templates
    resources :expenses
    resources :payments
  end
end

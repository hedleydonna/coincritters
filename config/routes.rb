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
    
    resources :income_templates, except: [:show] do
      member do
        patch :reactivate
      end
    end
    
    get "expenses", to: "expenses#index"
    post "expenses/start_next_month", to: "expenses#start_next_month", as: :start_next_month
    post "expenses/:expense_id/sweep_to_savings", to: "expenses#sweep_to_savings", as: :sweep_to_savings
    post "expenses/:id/mark_paid", to: "expenses#mark_paid", as: :mark_expense_paid
    resources :payments, only: [:new, :create]
    resources :expenses, only: [:new, :create, :edit, :update, :destroy]
    get "income_events", to: "income_events#index"
    resources :income_events, only: [:new, :create, :edit, :update, :destroy] do
      member do
        patch :mark_received
      end
    end
  end

  get "dashboard", to: "dashboard#index"
  post "dashboard/reset_data", to: "dashboard#reset_data", as: :reset_data
  post "dashboard/reset_all_data", to: "dashboard#reset_all_data", as: :reset_all_data
  get "up" => "rails/health#show", as: :rails_health_check

  get "/credits", to: "static#credits", as: :credits

  # Admin routes
  namespace :admin do
    root "dashboard#index"
    resources :users
    resources :income_templates
    resources :income_events
    resources :monthly_budgets
    resources :expense_templates
    resources :expenses
    resources :payments
  end
end

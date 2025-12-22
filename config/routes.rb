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
        patch :toggle_auto_create
      end
    end
    
    get "expenses", to: "expenses#index"
    post "expenses/start_next_month", to: "expenses#start_next_month", as: :start_next_month
    post "expenses/:expense_id/sweep_to_savings", to: "expenses#sweep_to_savings", as: :sweep_to_savings
    post "expenses/:id/mark_paid", to: "expenses#mark_paid", as: :mark_expense_paid
    resources :payments, only: [:new, :create, :destroy]
    resources :expenses, only: [:new, :create, :edit, :update, :destroy] do
      member do
        post :add_payment
      end
    end
    get "income_events", to: "income_events#index"
    resources :income_events, only: [:new, :create, :edit, :update, :destroy] do
      member do
        patch :mark_received
        patch :reset_to_expected
      end
    end
    
    get "money_map", to: "money_map#index", as: :money_map
    get "settings", to: "settings#index", as: :settings
  end

  get "dashboard", to: "dashboard#index"
  post "dashboard/reset_data", to: "dashboard#reset_data", as: :reset_data
  post "dashboard/reset_all_data", to: "dashboard#reset_all_data", as: :reset_all_data
  post "dashboard/clear_income_events", to: "dashboard#clear_income_events", as: :clear_income_events
  post "dashboard/clear_expenses", to: "dashboard#clear_expenses", as: :clear_expenses
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

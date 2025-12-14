# Admin::BaseController Documentation

## Overview

The `Admin::BaseController` is the base controller for all admin controllers in the Willow application. It provides authentication and authorization checks to ensure only admin users can access admin functionality.

## Location

`app/controllers/admin/base_controller.rb`

## Inheritance

- Inherits from `ApplicationController`
- All admin controllers inherit from `Admin::BaseController`

## Authentication & Authorization

### Authentication

All admin actions require the user to be authenticated:

```ruby
before_action :authenticate_user!
```

This ensures only logged-in users can access admin pages.

### Authorization

All admin actions require the user to have admin privileges:

```ruby
before_action :ensure_admin
```

**Authorization Logic:**
- Checks if `current_user&.admin?` returns `true`
- If not admin, redirects to `root_path` with alert: "You don't have permission to access this page."

## Private Methods

### `ensure_admin`

```ruby
def ensure_admin
  unless current_user&.admin?
    redirect_to root_path, alert: "You don't have permission to access this page."
  end
end
```

**Behavior:**
- Checks if the current user has admin privileges
- Uses safe navigation (`&.`) to handle nil users
- Redirects non-admin users to the home page with an error message
- Does nothing if the user is an admin (allows the action to proceed)

## Admin Controllers

All controllers in the `Admin` namespace inherit from this controller:

- `Admin::DashboardController`
- `Admin::ExpenseController`
- `Admin::ExpenseTemplatesController`
- `Admin::MonthlyBudgetsController`
- `Admin::PaymentsController`
- `Admin::IncomesController`
- `Admin::IncomeEventsController`
- `Admin::UsersController`

## Routes

All admin routes are namespaced under `/admin`:

```ruby
namespace :admin do
  root "dashboard#index"
  resources :users
  resources :incomes
  resources :income_events
  resources :monthly_budgets
  resources :expense_templates
  resources :expense
  resources :payments
end
```

## Security Considerations

1. **Double Protection**: Both authentication (`authenticate_user!`) and authorization (`ensure_admin`) are required
2. **Safe Navigation**: Uses `&.` to prevent errors if `current_user` is nil
3. **Clear Error Messages**: Provides user-friendly error messages when access is denied
4. **Consistent Behavior**: All admin controllers inherit this protection automatically

## Usage Example

```ruby
class Admin::ExpenseController < Admin::BaseController
  # Automatically has authentication and admin check
  # No need to add before_action :authenticate_user! or :ensure_admin
end
```

---

**Last Updated**: December 2025


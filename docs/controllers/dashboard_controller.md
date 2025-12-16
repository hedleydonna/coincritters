# DashboardController Documentation

## Overview

The `DashboardController` provides the main dashboard view for authenticated users. This is the primary interface users see after logging in.

## Location

`app/controllers/dashboard_controller.rb`

## Inheritance

- Inherits from `ApplicationController`
- Requires user authentication

## Routes

- **GET** `/dashboard` - User dashboard
- **GET** `/` - Root path (redirects to dashboard for authenticated users)

## Actions

### `index`

Displays the user's dashboard with financial overview.

**Behavior:**
- Automatically creates current month budget if it doesn't exist (`current_user.current_budget!`)
- Calculates financial statistics with safe nil handling
- Includes error handling with fallback to safe defaults

**Instance Variables:**
- `@budget` - Current month's budget (created if missing)
- `@total_income` - Total actual income for current month (from `@budget.total_actual_income`)
- `@expected_income` - Expected income for current month (from `@budget.expected_income`)
- `@total_spent` - Total spent across all expenses (from `@budget.total_spent`)
- `@remaining` - Remaining amount (total_actual_income - total_spent)
- `@flex_fund` - Remaining unassigned money (from `@budget.remaining_to_assign`)

**Error Handling:**
- If any error occurs, sets all variables to safe defaults (0 or nil)
- Logs errors to Rails logger for debugging

## Access Control

- **Requires authentication** - Users must be logged in to access the dashboard
- Uses `before_action :authenticate_user!` to ensure authentication

## Views

- `app/views/dashboard/index.html.erb` - User dashboard view

## Route Configuration

The dashboard is configured in `config/routes.rb`:

```ruby
# Dashboard route
get "dashboard", to: "dashboard#index"

# Root path for authenticated users
authenticated :user do
  root "dashboard#index", as: :authenticated_root
end
```

**Behavior:**
- Authenticated users accessing `/` are redirected to `/dashboard`
- The dashboard is accessible at `/dashboard` for authenticated users

## Post-Authentication Redirect

After users sign in, they are automatically redirected to the dashboard (configured in `ApplicationController`):

```ruby
def after_sign_in_path_for(resource)
  dashboard_path
end
```

## Usage

The dashboard typically displays:
- User's monthly budgets
- Recent expense and payment
- Financial overview and summaries
- Quick actions and navigation
- User-specific data and statistics

---

**Last Updated**: December 2025


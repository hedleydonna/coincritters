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

Displays the user's dashboard.

**Behavior:**
- No instance variables are set in the controller
- The view can access `current_user` to display user-specific data
- Renders the dashboard view

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


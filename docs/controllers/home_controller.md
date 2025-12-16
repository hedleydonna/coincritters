# HomeController Documentation

## Overview

The `HomeController` handles the public landing page for unauthenticated users. It provides the initial entry point to the CoinCritters application.

## Location

`app/controllers/home_controller.rb`

## Inheritance

- Inherits from `ApplicationController`
- No authentication required (public access)

## Routes

- **GET** `/` - Public landing page (root path for unauthenticated users)

**Note:** For authenticated users, the root path redirects to the dashboard (configured in `routes.rb`).

## Actions

### `index`

Displays the public landing page.

**Behavior:**
- No instance variables are set
- Renders the public landing page view
- Accessible to all users (authenticated and unauthenticated)

## Access Control

- **No authentication required** - This is a public page
- Accessible to both authenticated and unauthenticated users

## Views

- `app/views/home/index.html.erb` - Public landing page

## Route Configuration

The root route behavior is configured in `config/routes.rb`:

```ruby
# Public splash page
root to: "home#index"

# For authenticated users, root redirects to dashboard
authenticated :user do
  root "dashboard#index", as: :authenticated_root
end
```

**Behavior:**
- **Unauthenticated users**: Root path (`/`) shows the home page
- **Authenticated users**: Root path (`/`) redirects to the dashboard

## Usage

This controller serves as the entry point for:
- Marketing/landing page content
- User registration prompts
- Application overview
- Public information about the application

---

**Last Updated**: December 2025


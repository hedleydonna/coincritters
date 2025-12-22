# ApplicationController Documentation

## Overview

The `ApplicationController` is the base controller for all controllers in the CoinCritters application. It provides common functionality including authentication configuration, parameter sanitization, and redirect handling.

## Location

`app/controllers/application_controller.rb`

## Inheritance

- Inherits from `ActionController::Base`
- All other controllers inherit from `ApplicationController` (directly or indirectly)

## Key Features

### Authentication Redirect

After a user signs in, they are automatically redirected to the Money Map:

```ruby
def after_sign_in_path_for(resource)
  money_map_path
end
```

This ensures users land on the Money Map (the main dashboard) after authentication, which provides a complete overview of their financial situation.

### Devise Parameter Configuration

The controller configures which parameters Devise allows during user registration and account updates:

```ruby
def configure_permitted_parameters
  devise_parameter_sanitizer.permit(:sign_up, keys: [:display_name])
  devise_parameter_sanitizer.permit(:account_update, keys: [:display_name, :email])
end
```

**Permitted Parameters:**
- **Sign Up**: `display_name` (optional user-friendly name)
- **Account Update**: `display_name`, `email` (users can update their name and email)

## Callbacks

- `before_action :configure_permitted_parameters, if: :devise_controller?`
  - Automatically configures Devise parameter sanitization for Devise controllers
  - Only runs for controllers that are Devise controllers

## Usage

This controller is not accessed directly. It serves as the base class for all other controllers in the application, providing shared functionality.

## Related Controllers

All controllers inherit from `ApplicationController`:
- `HomeController`
- `DashboardController`
- `StaticController`
- `Admin::BaseController` (which then serves as base for all admin controllers)

---

**Last Updated**: December 2025

**Recent Changes (December 2025)**:
- Changed `after_sign_in_path_for` to redirect to `money_map_path` instead of `dashboard_path`
- Money Map is now the main landing page after login


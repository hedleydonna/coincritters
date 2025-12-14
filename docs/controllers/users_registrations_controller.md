# Users::RegistrationsController Documentation

## Overview

The `Users::RegistrationsController` extends Devise's default registration controller to customize user registration and profile update behavior. It allows users to update their profile (display_name and email) without requiring their password.

## Location

`app/controllers/users/registrations_controller.rb`

## Inheritance

- Inherits from `Devise::RegistrationsController`
- Standard Devise authentication flow

## Routes

Standard Devise routes for user registration:
- **GET** `/users/sign_up` - User registration form
- **POST** `/users` - Create new user account
- **GET** `/users/edit` - Edit user profile
- **PATCH/PUT** `/users` - Update user profile
- **DELETE** `/users` - Delete user account

## Customizations

### Profile Updates Without Password

**Override:** `update_resource` method

**Behavior:**
- Allows users to update `display_name` and `email` without entering their password
- Uses `update_without_password` to bypass password requirement
- Only permits `:display_name` and `:email` updates

**Code:**
```ruby
def update_resource(resource, params)
  resource.update_without_password(params.slice(:display_name, :email))
end
```

### Parameter Sanitization

**Sign Up Parameters:**
- Permits: `display_name`, `email`, `password`, `password_confirmation`

**Account Update Parameters:**
- Permits: `display_name`, `email` (no password required)

### After Update Redirect

**Behavior:**
- After updating profile, redirects to `dashboard_path` instead of default Devise behavior

**Code:**
```ruby
def after_update_path_for(resource)
  dashboard_path
end
```

## Access Control

- Standard Devise authentication
- Users can only edit their own profile
- Registration is public (unless configured otherwise in Devise)

## Related Models

- **User** - The model being managed

## Views

Standard Devise views in `app/views/devise/registrations/`:
- `new.html.erb` - Registration form
- `edit.html.erb` - Profile edit form

## Usage Examples

### User Registration

```ruby
POST /users
{
  user: {
    email: "user@example.com",
    password: "password123",
    password_confirmation: "password123",
    display_name: "John Doe"
  }
}
```

### Profile Update (No Password Required)

```ruby
PATCH /users
{
  user: {
    display_name: "Jane Doe",
    email: "jane@example.com"
  }
}
# No password field required
```

## Key Features

1. **Password-Free Updates**: Users can update their display name and email without entering password
2. **Display Name**: Custom field added to user registration
3. **Dashboard Redirect**: After profile update, redirects to dashboard instead of root

---

**Last Updated**: December 2025


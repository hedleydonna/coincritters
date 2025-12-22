# SettingsController Documentation

## Overview

The `SettingsController` provides a settings page for users to manage their account and preferences. Currently, it serves as a hub for account-related actions and can be expanded with additional settings in the future.

## Location

`app/controllers/settings_controller.rb`

## Inheritance

- Inherits from `ApplicationController`
- Requires authentication (`before_action :authenticate_user!`)

## Routes

- **GET** `/settings` - View settings page

## Actions

### `index`

Displays the settings page with account management options.

**Instance Variables:**
- None currently (can be expanded for future settings)

**View Features:**
- Link to edit user profile (email, password, display name)
- About section with app information
- Link to credits page

## Related Models

- **User** - Current user's account information

## Views

- `app/views/settings/index.html.erb` - Settings page

## Usage Examples

### Viewing Settings

```ruby
GET /settings
# Shows settings page
```

## Future Enhancements

The settings page can be expanded to include:
- Notification preferences
- Budget defaults
- Display preferences
- Data export/import
- Account deletion

---

**Last Updated**: December 2025


# StaticController Documentation

## Overview

The `StaticController` handles static pages that don't require dynamic data or complex logic. Currently, it manages the credits/attributions page.

## Location

`app/controllers/static_controller.rb`

## Inheritance

- Inherits from `ApplicationController`
- No authentication required (public access)

## Routes

- **GET** `/credits` - Credits/attributions page

Defined in `config/routes.rb`:

```ruby
get "/credits", to: "static#credits", as: :credits
```

## Actions

### `credits`

Displays the credits/attributions page.

**Behavior:**
- No instance variables are set
- Renders the static credits page
- Accessible to all users (authenticated and unauthenticated)

## Access Control

- **No authentication required** - This is a public page
- Accessible to both authenticated and unauthenticated users

## Views

- `app/views/static/credits.html.erb` - Credits/attributions page

## Usage

The credits page typically displays:
- Application credits
- Third-party library attributions
- License information
- Developer information
- Acknowledgments

## Future Expansion

This controller can be extended to handle other static pages such as:
- About page
- Privacy policy
- Terms of service
- Help/documentation
- FAQ

---

**Last Updated**: December 2025


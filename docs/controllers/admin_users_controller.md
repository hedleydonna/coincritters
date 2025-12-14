# Admin::UsersController Documentation

## Overview

The `Admin::UsersController` provides read, update, and delete functionality for managing users in the admin interface. This controller allows admins to view, edit, and delete user accounts.

## Location

`app/controllers/admin/users_controller.rb`

## Inheritance

- Inherits from `Admin::BaseController`
- Requires authentication and admin privileges

## Routes

All routes are namespaced under `/admin/users`:

- **GET** `/admin/users` - List all users (index)
- **GET** `/admin/users/:id` - Show user details
- **GET** `/admin/users/:id/edit` - Show edit user form
- **PATCH/PUT** `/admin/users/:id` - Update a user
- **DELETE** `/admin/users/:id` - Delete a user

**Note:** This controller does not provide `new` or `create` actions. Users are created through the registration system (Devise).

## Actions

### `index`

Lists all users.

**Instance Variables:**
- `@users` - All users, ordered by creation date (newest first)

### `show`

Displays detailed information about a specific user.

**Instance Variables:**
- `@user` - The user to display (set by `before_action :set_user`)

### `edit`

Shows the form to edit an existing user.

**Instance Variables:**
- `@user` - The user to edit (set by `before_action :set_user`)

### `update`

Updates an existing user from form parameters.

**Success:**
- Redirects to `admin_user_path(@user)` with success notice: "User was successfully updated."

**Failure:**
- Re-renders the `edit` template with `:unprocessable_entity` status

### `destroy`

Deletes a user account.

**Behavior:**
- Destroys the user (cascades to all associated records)
- Redirects to `admin_users_path` with success notice: "User was successfully deleted."

**Warning:** Deleting a user will cascade delete all associated:
- Incomes
- Income Events
- Monthly Budgets
- Expense (through budgets)
- Payments (through expense)
- ExpenseTemplates

## Callbacks

### `before_action :set_user`

Sets `@user` for `show`, `edit`, `update`, and `destroy` actions:

```ruby
def set_user
  @user = User.find(params[:id])
end
```

## Strong Parameters

### `user_params`

Permits the following parameters:

- `email` - User's email address (string, required, unique)
- `display_name` - User's display name (string, nullable)
- `admin` - Whether the user has admin privileges (boolean, default: false)

**Note:** Password changes are handled through Devise's password reset functionality, not through this controller.

## Access Control

- Requires user authentication (`before_action :authenticate_user!` from `Admin::BaseController`)
- Requires admin privileges (`before_action :ensure_admin` from `Admin::BaseController`)

## Related Models

- **User** - The model being managed
- All other models in the application (users have many associations)

## Views

- `app/views/admin/users/index.html.erb` - List of all users
- `app/views/admin/users/show.html.erb` - User details
- `app/views/admin/users/edit.html.erb` - Edit user form

## Usage Examples

### Updating a User

```ruby
PATCH /admin/users/1
{
  user: {
    email: "updated@example.com",
    display_name: "John Doe",
    admin: false
  }
}
```

### Granting Admin Privileges

```ruby
PATCH /admin/users/1
{
  user: {
    admin: true
  }
}
```

### Removing Admin Privileges

```ruby
PATCH /admin/users/1
{
  user: {
    admin: false
  }
}
```

## Security Considerations

1. **Admin-Only Access**: Only users with `admin: true` can access this controller
2. **Cascade Deletion**: Deleting a user removes all their data - use with caution
3. **Email Uniqueness**: Email addresses must be unique across all users
4. **No Password Management**: Passwords are managed through Devise, not this controller

---

**Last Updated**: December 2025


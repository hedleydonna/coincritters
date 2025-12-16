# User Model Documentation

## Overview

The User model represents user accounts in the CoinCritters application. It uses Devise for authentication and manages all user-related data including budgets, expenses, income templates, and income events. Each user has their own isolated set of financial data.

## Database Table

**Table Name:** `users`

### Schema

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| `id` | bigint | Primary Key | Auto-incrementing unique identifier |
| `email` | string | NOT NULL, Unique | User's email address (used for authentication) |
| `encrypted_password` | string | NOT NULL | Encrypted password (managed by Devise) |
| `reset_password_token` | string | Unique, Nullable | Token for password reset (managed by Devise) |
| `reset_password_sent_at` | datetime | Nullable | When password reset was sent (managed by Devise) |
| `remember_created_at` | datetime | Nullable | When "remember me" was set (managed by Devise) |
| `display_name` | string | Nullable | User-friendly display name (optional) |
| `admin` | boolean | NOT NULL, Default: false | Whether user has admin privileges |
| `created_at` | datetime | NOT NULL | Record creation timestamp |
| `updated_at` | datetime | NOT NULL | Last update timestamp |

### Indexes

- **Email Index**: Unique index on `email` - ensures email uniqueness and fast lookups
- **Reset Password Token Index**: Unique index on `reset_password_token` - for password reset functionality

### Referential Integrity

**Note:** This codebase does not use database-level foreign key constraints. Referential integrity is enforced at the model level via `belongs_to` validations in Rails 5+.

All related models reference `users.id` via `belongs_to :user` associations:
- `income_templates.user_id` references `users.id`
- `income_events.user_id` references `users.id`
- `monthly_budgets.user_id` references `users.id`
- `expense_templates.user_id` references `users.id`

Cascade deletion is handled via `dependent: :destroy` in model associations, not database-level foreign keys.

## Model Location

`app/models/user.rb`

## Devise Configuration

The User model uses Devise for authentication with the following modules:

- **`:database_authenticatable`**: Allows users to sign in with email and password
- **`:registerable`**: Allows users to create accounts
- **`:recoverable`**: Allows users to reset forgotten passwords
- **`:rememberable**`: Allows users to stay signed in with "remember me"
- **`:validatable`**: Provides email and password validations

## Associations

### Has Many

- **Income Templates**: User has many income templates
  ```ruby
  user.income_templates  # Returns collection of IncomeTemplate objects
  ```
  - **Dependent Behavior**: `destroy` - when a user is deleted, all their income templates are deleted

- **Income Events**: User has many income events
  ```ruby
  user.income_events  # Returns collection of IncomeEvent objects
  ```
  - **Dependent Behavior**: `destroy` - when a user is deleted, all their income events are deleted

- **Monthly Budgets**: User has many monthly budgets
  ```ruby
  user.monthly_budgets  # Returns collection of MonthlyBudget objects
  ```
  - **Dependent Behavior**: `destroy` - when a user is deleted, all their monthly budgets are deleted

- **Expense Templates**: User has many expense templates
  ```ruby
  user.expense_templates  # Returns collection of ExpenseTemplate objects
  ```
  - **Dependent Behavior**: `destroy` - when a user is deleted, all their expense templates are deleted

### Has Many Through

- **Expenses**: User has many expenses through monthly budgets
  ```ruby
  user.expenses  # Returns collection of Expense objects across all budgets
  ```
  - **Dependent Behavior**: Cascades through monthly budgets - when a user is deleted, all their expenses are deleted

## Validations

### Devise Validations

Devise automatically provides validations for:
- **Email**: Must be present, valid email format, and unique
- **Password**: Must be present (on create), minimum length (configurable in Devise), and confirmation match (if provided)

### Custom Validations

No additional custom validations are defined in the User model. All validations come from Devise's `:validatable` module.

## Instance Methods

### Admin Methods

- `admin?` - Returns `true` if the user has admin privileges
  ```ruby
  user.admin?  # => true if admin == true, false otherwise
  ```

### Budget Access Methods

- `current_budget` - Returns the current month's budget (read-only, returns `nil` if doesn't exist)
  ```ruby
  user.current_budget  # => MonthlyBudget object for current month, or nil
  ```

- `current_budget!` - Returns the current month's budget, creating it if it doesn't exist
  ```ruby
  user.current_budget!  # => MonthlyBudget object for current month (creates if missing)
  ```
  - Automatically creates expenses from active expense templates with `auto_create: true`
  - Automatically creates income events from active income templates with `auto_create: true`
  - Returns the newly created or existing budget

- `create_next_month_budget!` - Creates next month's budget if it doesn't exist
  ```ruby
  user.create_next_month_budget!  # => MonthlyBudget object for next month, or nil if already exists
  ```
  - Returns `nil` if next month's budget already exists
  - Automatically creates expenses from active expense templates with `auto_create: true`
  - Automatically creates income events from active income templates with `auto_create: true`
  - Returns the newly created budget

### Savings Methods (Deprecated)

- `total_actual_savings_this_month` - Returns 0 (savings tracking removed)
  ```ruby
  user.total_actual_savings_this_month  # => 0
  ```
  - **Note**: This method is kept for backward compatibility but always returns 0
  - TODO: Re-implement if savings tracking is needed with a different approach

- `total_actual_savings_all_time` - Returns 0 (savings tracking removed)
  ```ruby
  user.total_actual_savings_all_time  # => 0
  ```
  - **Note**: This method is kept for backward compatibility but always returns 0

- `total_savings` - Alias for `total_actual_savings_all_time`
  ```ruby
  user.total_savings  # => 0
  ```

## Business Rules

1. **Email Uniqueness**: Each user must have a unique email address (enforced by Devise and database unique index)

2. **Data Isolation**: Each user's financial data (budgets, expenses, income) is completely isolated from other users

3. **Cascade Deletion**: When a user is deleted, all associated data is automatically deleted:
   - All income templates
   - All income events
   - All monthly budgets (which cascades to expenses and payments)
   - All expense templates

4. **Admin Privileges**: Users with `admin: true` can access admin controllers and manage other users

5. **Budget Auto-Creation**: 
   - `current_budget!` automatically creates current month budget if missing
   - `create_next_month_budget!` creates next month budget if missing
   - Both methods auto-populate expenses and income events from templates

6. **Display Name**: Optional field for user-friendly name (can be `nil`)

## Usage Examples

### Creating a User (via Devise Registration)

```ruby
# Users are created through Devise registration
# POST /users
{
  user: {
    email: "user@example.com",
    password: "password123",
    password_confirmation: "password123",
    display_name: "John Doe"
  }
}
```

### Finding Users

```ruby
# Find by email
user = User.find_by(email: "user@example.com")

# Find by ID
user = User.find(1)

# Find all users
users = User.all
```

### Checking Admin Status

```ruby
user = User.find(1)

if user.admin?
  # User has admin privileges
end
```

### Accessing Current Budget

```ruby
user = User.find(1)

# Get current budget (returns nil if doesn't exist)
budget = user.current_budget

# Get or create current budget
budget = user.current_budget!
# => Creates budget if missing, auto-populates expenses and income events
```

### Creating Next Month Budget

```ruby
user = User.find(1)

# Create next month budget (only if doesn't exist)
budget = user.create_next_month_budget!
# => Creates budget for next month, auto-populates expenses and income events
# => Returns nil if next month budget already exists
```

### Accessing User's Financial Data

```ruby
user = User.find(1)

# Get all monthly budgets
budgets = user.monthly_budgets

# Get all expenses (across all budgets)
expenses = user.expenses

# Get all income templates
income_templates = user.income_templates

# Get all income events
income_events = user.income_events

# Get all expense templates
expense_templates = user.expense_templates
```

### Granting Admin Privileges

```ruby
user = User.find(1)
user.update(admin: true)
user.admin?  # => true
```

### Updating User Profile

```ruby
user = User.find(1)

# Update display name
user.update(display_name: "Jane Doe")

# Update email (requires password confirmation in Devise)
user.update(email: "newemail@example.com")
```

## Devise Integration

### Authentication Flow

Users authenticate using Devise's standard authentication flow with the following routes:

- **Sign Up**: `POST /users` (via custom `Users::RegistrationsController`)
- **Sign In**: `POST /users/sign_in` (via default `Devise::SessionsController`)
- **Sign Out**: `DELETE /users/sign_out` (via default `Devise::SessionsController`)
- **Password Reset**: `POST /users/password` (via default `Devise::PasswordsController`)
- **Password Reset Edit**: `GET /users/password/edit?reset_password_token=...` (via default `Devise::PasswordsController`)

### Customized Controllers

The application customizes the following Devise controllers:

#### `Users::RegistrationsController` (Customized)

**Location**: `app/controllers/users/registrations_controller.rb`

**Customizations**:
- Allows updating `display_name` and `email` without requiring password
- Uses `update_without_password` for profile updates
- Redirects to dashboard after profile update (instead of root)
- Permits `display_name` parameter during sign up and account update

**Documentation**: See `docs/controllers/users_registrations_controller.md`

### Default Devise Controllers

The following Devise controllers use default behavior (no customizations):

- **`Users::SessionsController`**: Standard sign in/sign out (empty stub, uses Devise defaults)
- **`Users::PasswordsController`**: Standard password reset (empty stub, uses Devise defaults)
- **`Users::ConfirmationsController`**: Email confirmation (if enabled, uses Devise defaults)
- **`Users::UnlocksController`**: Account unlock (if enabled, uses Devise defaults)
- **`Users::OmniauthCallbacksController`**: OAuth callbacks (if enabled, uses Devise defaults)

**Note**: These controllers exist as empty stubs in `app/controllers/users/` but are not customized. They inherit default behavior from Devise.

### Parameter Sanitization

Configured in `ApplicationController`:
- **Sign Up**: Permits `display_name` (in addition to Devise defaults: `email`, `password`, `password_confirmation`)
- **Account Update**: Permits `display_name` and `email` (no password required for profile updates)

### Post-Authentication Redirect

Configured in `ApplicationController`:
- After sign in, users are redirected to `dashboard_path` (instead of root)

### Devise Modules Enabled

The User model uses the following Devise modules (configured in `app/models/user.rb`):

1. **`:database_authenticatable`**: Email/password authentication
2. **`:registerable`**: User registration (sign up)
3. **`:recoverable`**: Password reset functionality
4. **`:rememberable`**: "Remember me" functionality
5. **`:validatable`**: Email and password validations

**Not Enabled**:
- `:confirmable` - Email confirmation (not used)
- `:lockable` - Account locking after failed attempts (not used)
- `:timeoutable` - Session timeout (not used)
- `:trackable` - Sign in tracking (not used)
- `:omniauthable` - OAuth authentication (not used)

## Related Models

- **IncomeTemplate** - User has many income templates
- **IncomeEvent** - User has many income events
- **MonthlyBudget** - User has many monthly budgets
- **ExpenseTemplate** - User has many expense templates
- **Expense** - User has many expenses (through monthly budgets)
- **Payment** - User has many payments (through expenses and monthly budgets)

## Admin Dashboard

Users can be managed through the admin dashboard:
- **View All**: `/admin/users`
- **View Details**: `/admin/users/:id`
- **Edit**: `/admin/users/:id/edit`
- **Delete**: `/admin/users/:id` (DELETE)

The admin dashboard allows:
- Viewing all users
- Editing user email, display name, and admin status
- Deleting users (cascades to all associated data)

## Security Considerations

1. **Password Encryption**: Passwords are encrypted using Devise's bcrypt encryption
2. **Email Uniqueness**: Email addresses must be unique (enforced at database level)
3. **Admin Access**: Only users with `admin: true` can access admin controllers
4. **Data Isolation**: Users can only access their own data (enforced at controller level)
5. **Cascade Deletion**: Deleting a user removes all their data - use with caution

## Migration History

- Initial user table creation with Devise fields
- Added `display_name` field
- Added `admin` field

## Future Enhancements

Potential additions to the User model:
- **Profile Picture**: Avatar/image upload
- **Preferences**: User settings and preferences
- **Notifications**: Email notification preferences
- **Time Zone**: User timezone for date/time display
- **Currency**: Default currency preference
- **Language**: Localization preferences
- **Two-Factor Authentication**: Additional security layer
- **Account Deactivation**: Soft delete instead of hard delete

---

**Last Updated**: December 2025


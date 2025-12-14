# Willow Models Documentation

This document describes the data models used in the Willow application.

## Overview

Willow currently uses four models: **User**, **Income**, **IncomeType**, and **IncomeEvent**. The application is built with Ruby on Rails and uses Devise for authentication.

---

## User Model

### Location
`app/models/user.rb`

### Description
The User model represents registered users of the Willow application. It handles authentication, user profiles, and account management.

### Database Table
`users`

### Schema

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| `id` | bigint | Primary Key | Auto-incrementing unique identifier |
| `email` | string | NOT NULL, Unique Index | User's email address (used for login) |
| `encrypted_password` | string | NOT NULL | Encrypted password (via Devise) |
| `reset_password_token` | string | Unique Index | Token for password reset |
| `reset_password_sent_at` | datetime | | Timestamp when password reset was sent |
| `remember_created_at` | datetime | | Timestamp for "remember me" functionality |
| `display_name` | string | | Optional display name for the user |
| `admin` | boolean | NOT NULL, Default: false | Admin privileges flag |
| `created_at` | datetime | NOT NULL | Account creation timestamp |
| `updated_at` | datetime | NOT NULL | Last update timestamp |

### Indexes

- **Email Index**: Unique index on `email` column
- **Reset Password Token Index**: Unique index on `reset_password_token` column

### Devise Modules

The User model includes the following Devise authentication modules:

#### `:database_authenticatable`
- Handles password encryption and authentication
- Validates password presence and length (minimum 6 characters)
- Provides `authenticate` method for login

#### `:registerable`
- Allows users to sign up for accounts
- Handles user registration process
- Provides sign-up forms and controllers

#### `:recoverable`
- Enables password reset functionality
- Generates secure reset tokens
- Sends password reset emails
- Tokens expire after 6 hours (default)

#### `:rememberable`
- Allows users to stay logged in
- Uses cookies to remember user sessions
- Configurable expiration period

#### `:validatable`
- Validates email format
- Validates password length (6-128 characters)
- Ensures email uniqueness

### Available Methods

#### Authentication Methods
- `authenticate(password)` - Validates password and returns user if correct
- `valid_password?(password)` - Checks if password is valid

#### Password Reset Methods
- `send_reset_password_instructions` - Sends password reset email
- `reset_password(new_password, confirmation)` - Resets password with new value

#### Profile Methods
- `display_name` - Returns display name or falls back to email username
- `update_without_password(params)` - Updates profile without password validation

#### Admin Methods
- `admin?` - Returns true if the user has admin privileges

#### Budget Methods
- `current_budget` - Returns the monthly budget for the current month (read-only, returns `nil` if no budget exists)
- `create_next_month_budget!` - Creates next month's budget (if it doesn't exist) and auto-creates expense, returns the budget or `nil` if already exists

#### Savings Methods
- `total_actual_savings_this_month` - Returns the total amount saved this month across all savings expense in the current budget (returns `0` if no current budget)
- `total_actual_savings_all_time` - Returns the total savings across all months and all budgets by summing `spent_amount` from all savings expense
- `total_savings` - Alias for `total_actual_savings_all_time` (shortcut for dashboard)

### Relationships

- `has_many :incomes` - A user can have multiple income sources
  - When a user is deleted, all associated incomes are also deleted (dependent: :destroy)
- `has_many :income_events` - A user can have multiple income events
  - When a user is deleted, all associated income events are also deleted (dependent: :destroy)
- `has_many :monthly_budgets` - A user can have multiple monthly budgets (one per month)
  - When a user is deleted, all associated monthly budgets are also deleted (dependent: :destroy)
- `has_many :expense, through: :monthly_budgets` - A user can access all expense through their monthly budgets
- `has_many :payment_categories` - A user can have multiple payment categories
  - When a user is deleted, all associated payment categories are also deleted (dependent: :destroy)

**Note**: Income types are global/shared resources and do not belong to individual users. All users share the same set of income types for categorizing their income events.

### Validations

- **Email**: 
  - Must be present
  - Must be unique
  - Must match email format regex
- **Password**: 
  - Must be present on creation
  - Minimum 6 characters
  - Maximum 128 characters

### Custom Attributes

#### `display_name`
- Optional string field
- Used for personalized greetings on dashboard
- Can be updated without password verification
- Falls back to email username if not set

#### `admin`
- Boolean field (default: false)
- Grants administrative privileges when set to true
- Admin users can access the admin dashboard
- Admin users can manage users and incomes
- Only existing admins can grant admin privileges to other users

### Security Features

1. **Password Encryption**: Passwords are encrypted using bcrypt (via Devise)
2. **Password Reset Tokens**: Cryptographically secure, time-limited tokens
3. **Email Uniqueness**: Prevents duplicate accounts
4. **Password Validation**: Enforces minimum length requirements

### Migration History

- `20251209010200_create_users.rb` - Initial users table creation
- `20251209170000_add_display_name_to_users.rb` - Added display_name column
- `20251209184017_add_admin_to_users.rb` - Added admin column

### Usage Examples

#### Creating a User
```ruby
user = User.create(
  email: "user@example.com",
  password: "password123",
  display_name: "John Doe"
)
```

#### Updating Profile
```ruby
user.update_without_password(
  display_name: "Jane Doe",
  email: "newemail@example.com"
)
```

#### Password Reset
```ruby
user.send_reset_password_instructions
# User receives email with reset link
```

#### Authentication
```ruby
user = User.find_by(email: "user@example.com")
if user&.valid_password?("password123")
  # User authenticated successfully
end
```

#### Working with Budgets
```ruby
user = User.first

# Get current month's budget (returns nil if none exists)
current = user.current_budget
# => #<MonthlyBudget ... month_year: "2025-12"> or nil

# Create next month's budget with auto-created expense
next_budget = user.create_next_month_budget!
# => #<MonthlyBudget ... month_year: "2026-01">
# Returns nil if budget already exists
# Automatically creates expense for payment categories with auto_create: true

# Get total savings for current month
monthly_savings = user.total_actual_savings_this_month
# => 300.00 (sum of spent_amount from savings expense this month)

# Get total savings across all months
lifetime_savings = user.total_actual_savings_all_time
# => 1500.00 (sum of spent_amount from all savings expense ever)

# Shortcut alias (same as total_actual_savings_all_time)
total = user.total_savings
# => 1500.00
```

---

## Income Model

For detailed documentation about the Income model, see [Income Model Documentation](./income_model.md).

The Income model represents income sources for users. Key features:
- Each income belongs to a user
- Tracks estimated amount, frequency, and active status
- Supports auto-create functionality for automatic income event generation (`auto_create`, `auto_day_of_month`)
- Validates uniqueness of income name per user
- Supports cascade deletion when user is deleted
- Has many income events (dependent: :destroy)

## Monthly Budget Model

For detailed documentation about the Monthly Budget model, see [Monthly Budget Model Documentation](./monthly_budget_model.md).

The Monthly Budget model represents monthly budget tracking for users. Key features:
- One budget per user per month (unique constraint)
- Tracks total actual income, flex fund, and optional bank balance
- Validates month_year format (YYYY-MM)
- Supports cascade deletion when user is deleted
- Has many expense for payment categories
- Provides scopes for finding budgets (`current`, `for_month`, `by_month`, `for_user`)
- Calculates remaining income to assign and unassigned amounts
- Supports bank balance reconciliation with tolerance checking
- Auto-creates expense from payment categories with `auto_create: true`

---

## Payment Category Model

For detailed documentation about the Payment Category model, see [Payment Category Model Documentation](./payment_category_model.md).

The Payment Category model represents user-defined payment categories that can be reused across monthly budgets. Key features:
- Each category belongs to a user
- Defines group type (fixed vs variable) and savings status
- Supports default amounts and auto-creation settings
- Enforces unique category names per user
- Supports cascade deletion when user is deleted
- Has many expense that reference it

---

## ExpenseModel

For detailed documentation about the Expensemodel, see [ExpenseModel Documentation](./envelope_model.md).

The Expensemodel represents payment categories within monthly budgets. Key features:
- Each expensebelongs to a monthly budget and a payment category
- Tracks allotted amount; spent amount is calculated from related payment records
- Auto-fills `allotted_amount` from payment category's `default_amount` when creating
- Inherits name, group type, and savings status from payment category
- Enforces unique payment_category per budget
- Supports cascade deletion when monthly budget or payment category is deleted
- Provides scopes for filtering by type (`fixed`, `variable`, `savings`, `non_savings`, `over_budget`)
- Calculates remaining, available, and spent percentages
- Tracks if fixed bills are paid (`paid?` method)

---

## Income Event Model

For detailed documentation about the Income Event model, see [Income Event Model Documentation](./income_event_model.md).

The Income Event model represents actual income received events. Key features:
- Each income event belongs to a user (required)
- Has a free-form `income_type` string field for categorization (defaults to "Paycheck")
- Optionally linked to an income source
- Tracks actual amount, received date, and month/year attribution
- Supports both `month_year` (when received) and `assigned_month_year` (when attributed)
- Validates date formats and non-negative amounts

---

## Future Models

As the application grows, additional models may be added:

### Potential Models

- **WillowTree** - Represents user's virtual willow tree
- **Transaction** - Tracks user transactions/activities
- **Achievement** - User achievements and milestones
- **Subscription** - User subscription plans (if using Pay gem)

---

## Database Configuration

- **Database**: PostgreSQL
- **Adapter**: `pg` gem
- **Environment**: Separate databases for development, test, and production

---

## Notes

- All timestamps are automatically managed by Rails (`created_at`, `updated_at`)
- Devise handles most authentication logic automatically
- Custom controllers (`Users::RegistrationsController`) extend Devise functionality
- Profile updates can be made without password verification for better UX

---

---

## Payment Model

For detailed documentation about the Payment model, see [Payment Model Documentation](./payment_model.md).

The Payment model represents individual payment transactions within an expense This unified model consolidates all payment records (both fixed bills and variable expenses). Key features:
- Each payment record belongs to an envelope
- Tracks `amount`, `spent_on`, and optional `notes`
- `amount` must be greater than 0
- Provides scopes for querying by date, date range, and envelope
- Delegates `payment_group_name` to the associated expenses name (which comes from payment_category)
- Provides helper methods for date-based checks (`today?`, `this_week?`, `this_month?`)
- Supports cascade deletion when expenseis deleted

---

**Last Updated**: December 2025


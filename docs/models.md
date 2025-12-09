# Willow Models Documentation

This document describes the data models used in the Willow application.

## Overview

CoinCritters currently uses a single model: **User**. The application is built with Ruby on Rails and uses Devise for authentication.

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

### Relationships

Currently, the User model has no associations with other models. Future models may include:
- Has many relationships (e.g., posts, comments, transactions)
- Belongs to relationships (e.g., organization, subscription)

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

### Security Features

1. **Password Encryption**: Passwords are encrypted using bcrypt (via Devise)
2. **Password Reset Tokens**: Cryptographically secure, time-limited tokens
3. **Email Uniqueness**: Prevents duplicate accounts
4. **Password Validation**: Enforces minimum length requirements

### Migration History

- `20251209010200_create_users.rb` - Initial users table creation
- `20251209170000_add_display_name_to_users.rb` - Added display_name column

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

**Last Updated**: December 2025


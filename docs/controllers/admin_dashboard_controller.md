# Admin::DashboardController Documentation

## Overview

The `Admin::DashboardController` provides an administrative dashboard that displays overview statistics and recent records for all major models in the Willow application.

## Location

`app/controllers/admin/dashboard_controller.rb`

## Inheritance

- Inherits from `Admin::BaseController`
- Requires authentication and admin privileges

## Routes

- **GET** `/admin` - Admin dashboard (root)
- **GET** `/admin/dashboard` - Admin dashboard

## Actions

### `index`

Displays the admin dashboard with comprehensive statistics and recent records.

**Instance Variables Set:**

1. **User Statistics:**
   - `@user_count` - Total number of users
   - `@recent_users` - 5 most recently created users

2. **Income Statistics:**
   - `@income_count` - Total number of income records
   - `@active_income_count` - Number of active income records
   - `@recent_incomes` - 5 most recently created incomes (includes user)

3. **Income Event Statistics:**
   - `@income_event_count` - Total number of income events
   - `@recent_income_events` - 5 most recently created income events (includes user and income)

4. **Monthly Budget Statistics:**
   - `@monthly_budget_count` - Total number of monthly budgets
   - `@recent_monthly_budgets` - 5 most recently created monthly budgets (includes user)

5. **Envelope Statistics:**
   - `@envelope_count` - Total number of envelopes
   - `@recent_envelopes` - 5 most recently created envelopes (includes monthly_budget and user)

6. **Spending Statistics:**
   - `@spending_count` - Total number of spending records
   - `@recent_spendings` - 5 most recent spending records (includes envelope, monthly_budget, and user)

7. **Envelope Template Statistics:**
   - `@envelope_template_count` - Total number of envelope templates
   - `@recent_envelope_templates` - 5 most recently created envelope templates (includes user)

**Query Optimizations:**
- Uses `includes` to eager load associations and prevent N+1 queries
- Orders records by `created_at: :desc` to show newest first
- Limits recent records to 5 items each

## View

Renders `app/views/admin/dashboard/index.html.erb`

The view displays:
- Summary cards with counts for each model
- Tables showing recent records for each model
- Links to manage each resource type

## Access Control

- Requires user authentication (`before_action :authenticate_user!` from `Admin::BaseController`)
- Requires admin privileges (`before_action :ensure_admin` from `Admin::BaseController`)

## Usage

Admins can access the dashboard at `/admin` or `/admin/dashboard` to:
- Get an overview of all data in the system
- See recent activity across all models
- Quickly navigate to manage specific resources

---

**Last Updated**: December 2025


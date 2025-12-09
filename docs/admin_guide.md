# Willow Admin Guide

This guide describes the administrative features available in Willow.

## Overview

The admin dashboard provides administrative users with tools to manage the application, including user management and income tracking.

## Accessing the Admin Dashboard

### Requirements
- You must be logged in
- Your account must have admin privileges (`admin: true`)

### How to Access
1. Log in to your admin account
2. From your dashboard, click the **"Admin Dashboard"** button
3. You'll be redirected to `/admin`

**Note**: If you try to access admin routes without admin privileges, you'll be redirected to the home page with an error message.

## Admin Dashboard Features

### Dashboard Overview

The admin dashboard provides an at-a-glance view of:
- **Total Users**: Count of all registered users
- **Admin Users**: Count of users with admin privileges
- **Regular Users**: Count of non-admin users
- **Total Incomes**: Count of all income records
- **Active Incomes**: Count of active (non-deleted) income records

### Quick Actions

From the admin dashboard, you can quickly navigate to:
- **Manage Users**: View and manage all users
- **Manage Incomes**: View and manage all income records
- **Back to Dashboard**: Return to your personal dashboard

### Recent Activity

The dashboard displays:
- **Recent Users**: Last 5 users who registered
- **Recent Incomes**: Last 5 income records created

## User Management

### Viewing Users

Navigate to **Admin Dashboard** → **Manage Users** to see a list of all users.

The user list displays:
- Email address
- Display name
- Admin status (Admin/User badge)
- Join date
- Actions (View, Edit, Delete)

### Viewing User Details

Click **"View"** next to any user to see their detailed information:
- Email address
- Display name
- Admin status
- Account creation date
- Last update timestamp
- Action buttons (Edit, Delete)

### Editing Users

1. Navigate to the user's detail page
2. Click **"Edit User"**
3. Update any of the following fields:
   - Email
   - Display Name
   - Admin Status (checkbox)
4. Click **"Update User"**

**Important**: Only admins can grant or revoke admin privileges.

### Deleting Users

**Warning**: Deleting a user will permanently delete:
- The user account
- All associated income records (cascade deletion)

**To delete a user:**
1. Navigate to the user's detail page or the users list
2. Click **"Delete"** or **"Delete User"**
3. A confirmation dialog will appear asking: *"Are you sure you want to delete this user?"*
4. Click **"OK"** to confirm deletion
5. The user and all associated data will be permanently removed

**Note**: You cannot delete yourself. If you need to delete your own account, you must use the regular user account deletion flow from your profile page.

## Income Management

### Viewing Incomes

Navigate to **Admin Dashboard** → **Manage Incomes** to see a list of all income records.

The income list displays:
- Associated user
- Income name
- Estimated amount (formatted with commas)
- Frequency (weekly, bi-weekly, monthly, irregular)
- Active status (Yes/No badge)
- Actions (View, Edit, Delete)

### Viewing Income Details

Click **"View"** next to any income to see detailed information:
- Associated user
- Income name
- Estimated amount
- Frequency
- Active status
- Creation timestamp
- Last update timestamp
- Action buttons (Edit, Delete)

### Editing Incomes

1. Navigate to the income's detail page
2. Click **"Edit Income"**
3. Update any of the following fields:
   - User (assign to a different user)
   - Name
   - Estimated Amount
   - Frequency (dropdown: weekly, bi-weekly, monthly, irregular)
   - Active (checkbox)
4. Click **"Update Income"**

**Validation Rules:**
- Income name must be unique per user
- Estimated amount must be >= 0
- Frequency must be one of the allowed values

### Deleting Incomes

**To delete an income:**
1. Navigate to the income's detail page or the incomes list
2. Click **"Delete"** or **"Delete Income"**
3. A confirmation dialog will appear asking: *"Are you sure you want to delete this income?"*
4. Click **"OK"** to confirm deletion
5. The income record will be permanently removed

**Note**: Deleting an income does not delete the associated user.

## Security Features

### Authorization
- All admin routes require authentication
- All admin routes require admin privileges
- Non-admin users are redirected with an error message
- Unauthenticated users are redirected to the login page

### Delete Confirmations
- All delete actions require user confirmation
- Confirmation dialogs prevent accidental deletions
- Delete confirmations use browser-native dialogs

### Data Protection
- User deletion cascades to associated incomes
- All timestamps are tracked (`created_at`, `updated_at`)
- Validation prevents invalid data entry

## Best Practices

### User Management
- Review user details before making changes
- Be cautious when granting admin privileges
- Consider the impact before deleting users (all their data will be lost)

### Income Management
- Verify income amounts and frequencies are correct
- Use the "Active" flag to disable incomes instead of deleting when possible
- Ensure income names are descriptive and unique per user

### General Admin Practices
- Regularly review the dashboard statistics
- Monitor recent user registrations
- Keep track of income record activity
- Document any significant administrative actions

## Troubleshooting

### Can't Access Admin Dashboard
- **Check**: Are you logged in?
- **Check**: Does your account have `admin: true`?
- **Solution**: Contact another admin to grant you admin privileges

### Delete Button Not Working
- **Check**: Is JavaScript enabled in your browser?
- **Check**: Are you seeing the confirmation dialog?
- **Solution**: Ensure you're clicking "OK" in the confirmation dialog to proceed with deletion

### Cannot Delete Yourself
- This is by design to prevent accidental account deletion
- Use the regular profile deletion flow if needed

## Technical Details

### Admin Routes
All admin routes are namespaced under `/admin`:
- `/admin` - Dashboard
- `/admin/users` - User management
- `/admin/users/:id` - User details
- `/admin/incomes` - Income management
- `/admin/incomes/:id` - Income details

### Controllers
- `Admin::BaseController` - Base controller with authorization
- `Admin::DashboardController` - Dashboard statistics
- `Admin::UsersController` - User CRUD operations
- `Admin::IncomesController` - Income CRUD operations

### Delete Actions
- All delete actions use HTTP DELETE method
- Forms use `button_to` helper for reliable DELETE requests
- Confirmations use both `data-confirm` and `data-turbo-confirm` for compatibility

---

**Last Updated**: December 2025


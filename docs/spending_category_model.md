# Spending Category Model Documentation

## Overview

The `SpendingCategory` model represents user-defined spending categories that can be reused across monthly budgets. Each category defines the type of spending (fixed vs variable), whether it's a savings pot, default amounts, and auto-creation behavior. Envelopes reference spending categories to inherit their properties.

## Model Location

`app/models/spending_category.rb`

## Schema

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| `id` | bigint | Primary Key | Auto-incrementing unique identifier |
| `user_id` | bigint | NOT NULL, Foreign Key | References the user who owns this category |
| `name` | string | NOT NULL | Category name (e.g., "Rent", "Groceries", "Emergency Fund") |
| `group_type` | integer | NOT NULL, Default: 1 | 0 = fixed (rent, Netflix), 1 = variable (food, fun) |
| `is_savings` | boolean | NOT NULL, Default: false | true = savings pot (emergency fund, vacation, etc.) |
| `default_amount` | decimal(12,2) | Nullable | Default amount to allocate when creating envelopes |
| `auto_create` | boolean | NOT NULL, Default: true | Automatically create envelope in monthly budgets |
| `created_at` | datetime | NOT NULL | Record creation timestamp |
| `updated_at` | datetime | NOT NULL | Last update timestamp |

### Indexes

- **User ID + Name Index**: Composite unique index on `[user_id, name]` - ensures unique category names per user
- **User ID + Group Type Index**: Composite index on `[user_id, group_type]` - optimized for finding categories by type

### Foreign Keys

- `spending_categories.user_id` references `users.id` with `on_delete: :cascade`. If a user is deleted, all their spending categories are deleted.

## Associations

### Belongs To

- `belongs_to :user` - Each spending category belongs to a user who owns it

### Has Many

- `has_many :envelopes, dependent: :destroy` - A spending category can have many envelopes across different monthly budgets. When a category is deleted, all associated envelopes are deleted.

## Validations

### Presence Validations

- `validates :name, presence: true` - The category name must be present.

### Uniqueness Validations

- `validates :name, uniqueness: { scope: :user_id }` - Category names must be unique per user. Different users can have categories with the same name.

### Numericality Validations

- `validates :default_amount, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true` - The default amount must be greater than or equal to 0 if provided, but can be nil.

## Enums

- `enum :group_type, { fixed: 0, variable: 1 }, default: :variable` - Defines the two group types:
  - `fixed` (0): Recurring bills that are consistent (rent, Netflix, insurance)
  - `variable` (1): Flexible spending that varies (food, fun, entertainment)

The enum automatically provides:
- `group_type` attribute with string values ("fixed", "variable")
- Boolean methods: `fixed?`, `variable?`
- Scopes: `SpendingCategory.fixed`, `SpendingCategory.variable`

## Scopes

- `scope :fixed` - Returns only fixed spending categories
- `scope :variable` - Returns only variable spending categories
- `scope :savings` - Returns only savings categories (`is_savings: true`)
- `scope :non_savings` - Returns only non-savings categories (`is_savings: false`)
- `scope :auto_create` - Returns only categories with `auto_create: true`

## Instance Methods

- `display_name` - Returns a friendly display name. If it's a savings category, returns `"#{name} (Savings)"`, otherwise just the name.
  
- `group_type_text` - Returns a text description of the group type:
  - `"Fixed bill"` for fixed categories
  - `"Variable spending"` for variable categories

## Business Rules

1. **Unique Names Per User**: Each user can only have one category with a given name. Different users can have categories with the same name.

2. **Group Type Classification**: Categories are classified as either "fixed" (consistent recurring bills) or "variable" (flexible spending). This affects how envelopes are used in budgeting.

3. **Savings Pots**: Categories can be marked as savings pots, which are typically used for goals like emergency funds, vacations, or major purchases.

4. **Default Amounts**: Categories can have a default amount that will be used when automatically creating envelopes in monthly budgets.

5. **Auto-Create**: When `auto_create` is true, the system will automatically create envelopes for this category in monthly budgets. This is a future enhancement.

6. **Cascade Deletion**: When a user is deleted, all their spending categories are deleted. When a spending category is deleted, all associated envelopes are deleted.

## Usage Examples

### Creating a Spending Category

```ruby
user = User.find(1)

# Create a fixed spending category for rent
rent_category = SpendingCategory.create!(
  user: user,
  name: "Rent",
  group_type: :fixed,
  is_savings: false,
  default_amount: 1200.00,
  auto_create: true
)

# Create a variable spending category for groceries
groceries_category = SpendingCategory.create!(
  user: user,
  name: "Groceries",
  group_type: :variable,
  is_savings: false,
  default_amount: 500.00,
  auto_create: true
)

# Create a savings category
emergency_fund = SpendingCategory.create!(
  user: user,
  name: "Emergency Fund",
  group_type: :fixed,
  is_savings: true,
  default_amount: 300.00,
  auto_create: true
)
```

### Finding Categories

```ruby
user = User.find(1)

# Find all fixed categories
fixed_categories = user.spending_categories.fixed

# Find all savings categories
savings_categories = user.spending_categories.savings

# Find a specific category
rent = user.spending_categories.find_by(name: "Rent")
```

### Using with Envelopes

```ruby
category = SpendingCategory.find(1)
monthly_budget = MonthlyBudget.find(1)

# Create an envelope using this category
envelope = Envelope.create!(
  monthly_budget: monthly_budget,
  spending_category: category,
  # Name comes from the category
  allotted_amount: category.default_amount || 0
)

# The envelope inherits group_type and is_savings from the category
envelope.group_type  # => "fixed" (from category)
envelope.is_savings? # => false (from category)
```

### Display Methods

```ruby
category = SpendingCategory.find(1)

category.display_name      # => "Rent" or "Emergency Fund (Savings)"
category.group_type_text   # => "Fixed bill" or "Variable spending"
```

## Relationship with Envelopes

The `SpendingCategory` model is the parent of `Envelope`. Each envelope belongs to a spending category and inherits its `group_type` and `is_savings` properties. This design allows:

1. **Consistency**: All envelopes using the same category have the same type and savings status
2. **Reusability**: A single category can be used across multiple monthly budgets
3. **Centralized Management**: Changing a category's properties affects all envelopes using it
4. **Organization**: Users can define their spending categories once and reuse them

The envelope uses the category's `name` directly (via the `name` method, which delegates to `spending_category.name`) and tracks its own `allotted_amount` per monthly budget. The `spent_amount` is calculated from related spending records.


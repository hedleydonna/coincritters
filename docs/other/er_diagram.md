# Willow Database ER Diagram

This document contains the Entity-Relationship (ER) diagram for the Willow application database schema.

## Mermaid ER Diagram

```mermaid
erDiagram
    users {
        bigint id PK
        string email UK "NOT NULL, Unique"
        string encrypted_password "NOT NULL"
        string reset_password_token UK "Unique"
        datetime reset_password_sent_at
        datetime remember_created_at
        string display_name
        boolean admin "default: false, NOT NULL"
        datetime created_at
        datetime updated_at
    }

    income_templates {
        bigint id PK
        bigint user_id FK "NOT NULL"
        string name "NOT NULL"
        string frequency "default: 'monthly', NOT NULL"
        decimal estimated_amount "precision: 12, scale: 2, default: 0.0"
        boolean active "default: true, NOT NULL"
        boolean auto_create "default: false, NOT NULL"
        date due_date
        boolean last_payment_to_next_month
        datetime created_at
        datetime updated_at
    }

    income_events {
        bigint id PK
        bigint user_id FK "NOT NULL"
        bigint income_id FK "nullable"
        string custom_label
        string month_year "NOT NULL"
        boolean apply_to_next_month
        date received_on "NOT NULL"
        decimal actual_amount "precision: 12, scale: 2, default: 0.0"
        text notes
        datetime created_at
        datetime updated_at
    }

    monthly_budgets {
        bigint id PK
        bigint user_id FK "NOT NULL"
        string month_year "NOT NULL, Format: YYYY-MM"
        decimal total_actual_income "precision: 12, scale: 2, default: 0.0"
        decimal flex_fund "precision: 12, scale: 2, default: 0.0"
        decimal bank_balance "precision: 12, scale: 2, nullable"
        datetime created_at
        datetime updated_at
    }

    expense_templates {
        bigint id PK
        bigint user_id FK "NOT NULL"
        string name "NOT NULL"
        string frequency "default: 'monthly', NOT NULL"
        date due_date "nullable"
        decimal default_amount "precision: 12, scale: 2, default: 0.0"
        boolean auto_create "default: true, NOT NULL"
        boolean is_active "default: true, NOT NULL, soft delete"
        datetime created_at
        datetime updated_at
    }

    expense {
        bigint id PK
        bigint monthly_budget_id FK "NOT NULL"
        bigint expense_template_id FK "nullable - null for one-off expenses"
        decimal allotted_amount "precision: 12, scale: 2, default: 0.0, NOT NULL"
        string name "required for one-off expenses, optional override for template-based expenses"
        datetime created_at
        datetime updated_at
    }

    payments {
        bigint id PK
        bigint expense_id FK "NOT NULL"
        decimal amount "precision: 12, scale: 2, default: 0.0, NOT NULL"
        date spent_on "NOT NULL"
        text notes
        datetime created_at
        datetime updated_at
    }

    %% Relationships
    users ||--o{ income_templates : "has many"
    users ||--o{ income_events : "has many"
    users ||--o{ monthly_budgets : "has many"
    users ||--o{ expense_templates : "has many"

    income_templates ||--o{ income_events : "has many (optional)"
    
    monthly_budgets ||--o{ expense : "has many"
    
    expense_templates ||--o{ expense : "has many"
    
    expense ||--o{ payments : "has many"
```

## Relationship Details

### One-to-Many Relationships

1. **users → income_templates** (1:N)
   - One user can have many income sources
   - Delete behavior: When a user is deleted, all their income templates are deleted via `dependent: :destroy` in the User model

2. **users → income_events** (1:N)
   - One user can have many income events
   - Delete behavior: When a user is deleted, all their income events are deleted via `dependent: :destroy` in the User model

3. **users → monthly_budgets** (1:N)
   - One user can have many monthly budgets (one per month)
   - Delete behavior: When a user is deleted, all their monthly budgets are deleted via `dependent: :destroy` in the User model
   - Unique constraint: One budget per user per month (`user_id`, `month_year`)

4. **users → expense_templates** (1:N)
   - One user can have many expensetemplates (reusable templates for creating expense)
   - Delete behavior: When a user is deleted, all their expensetemplates are deleted via `dependent: :destroy` in the User model
   - Unique constraint: One template name per user (`user_id`, `name`)

5. **income_templates → income_events** (1:N, optional)
   - One income template can have many income events (tracking actual payments)
   - Optional relationship: Income events can exist without being linked to an income template
   - Delete behavior: When an income template is deleted, all related income events are deleted via `dependent: :destroy` in the IncomeTemplate model

6. **monthly_budgets → expense** (1:N)
   - One monthly budget can have many expense (payment categories for that month)
   - Delete behavior: When a monthly budget is deleted, all its expense are deleted via `dependent: :destroy` in the MonthlyBudget model
   - Unique constraint: One expenseper template per budget (`monthly_budget_id`, `expense_template_id`), unless name override is used

7. **expense_templates → expense** (1:N, optional)
   - One expensetemplate can be used in many expense (across different monthly budgets)
   - Templates provide default values (name, frequency, due_date, default_amount)
   - Expense can be template-based (has expense_template_id) or one-off (expense_template_id is null)
   - Template-based expenses can override template name on a per-month basis
   - One-off expenses require a name and don't use templates
   - Delete behavior: When an expensetemplate is deleted, only template-based related expenses are deleted via `dependent: :destroy` in the ExpenseTemplate model (one-off expenses are unaffected)

8. **expense → payments** (1:N)
   - One expensecan have many payment records (tracking individual transactions)
   - Delete behavior: When an expense is deleted, all its payment records are deleted via `dependent: :destroy` in the Expense model

## Unique Constraints

1. **users.email** - Unique email addresses
2. **users.reset_password_token** - Unique reset tokens
3. **income_templates(user_id, name)** - Unique income template name per user
4. **monthly_budgets(user_id, month_year)** - One budget per user per month
5. **expense_templates(user_id, name)** - Unique template name per user
6. **expense(monthly_budget_id, expense_template_id)** - Partial unique index: One expense per template per budget when expense_template_id IS NOT NULL (unless name override is used)
7. **expense(monthly_budget_id, name)** - Unique name per budget (for one-off expenses and name overrides)
7. **expense(monthly_budget_id, name)** - Unique name per budget when using name override

## Expense Types

Expenses can be either:
- **Template-based**: Has an `expense_template_id`, inherits name/frequency/due_date from template (unless name is overridden)
- **One-off**: `expense_template_id` is null, requires a `name`, uses default frequency ("monthly") and no due_date

## Override Fields

For template-based expenses:
- **name** (nullable): If set, overrides the template name for this expense
- When name is `NULL`, the expense uses the template's name
- Frequency and due_date always come from the template and cannot be overridden

For one-off expenses:
- **name** (required): Must be unique within the monthly budget
- Frequency defaults to "monthly"
- Due date is null

## Calculated Fields (Not in Database)

These fields are calculated at the model level and are not stored in the database:

- **expense.spent_amount** - Calculated as `payments.sum(:amount)` for that expense
- **expense.name** - For template-based: uses override if present, otherwise delegates to `expense_template.name`. For one-off: uses the stored `name` field.
- **expense.frequency** - For template-based: delegates to `expense_template.frequency`. For one-off: defaults to "monthly"
- **expense.due_date** - For template-based: delegates to `expense_template.due_date`. For one-off: nil

## Notes

- **Referential Integrity**: This codebase does not use database-level foreign key constraints. Referential integrity is enforced at the model level via `belongs_to` validations in Rails 5+. Cascade deletion is handled via `dependent: :destroy` in model associations.
- All tables include `created_at` and `updated_at` timestamps (managed by Rails)
- Decimal fields use `precision: 12, scale: 2` for currency values
- The `frequency` field in `expense_templates` can be: "monthly", "weekly", "biweekly", or "yearly"
- Expensetemplates serve as reusable templates for creating expense across multiple monthly budgets
- Expense can override template name to customize behavior for specific months

---

**Last Updated**: December 2025

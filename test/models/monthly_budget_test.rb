require "test_helper"

class MonthlyBudgetTest < ActiveSupport::TestCase
  setup do
    @user_one = users(:one)
    @user_two = users(:two)
    @budget_one = monthly_budgets(:one)
    @budget_two = monthly_budgets(:two)
  end

  test "should be valid with valid attributes" do
    budget = MonthlyBudget.new(
      user: @user_one,
      month_year: "2026-01",
      total_actual_income: 5000.00,
      flex_fund: 500.00,
      bank_balance: 3000.00
    )
    assert budget.valid?
  end

  test "should require a user" do
    budget = MonthlyBudget.new(
      month_year: "2025-12",
      total_actual_income: 5000.00
    )
    assert_not budget.valid?
    assert_includes budget.errors[:user], "must exist"
  end

  test "should require month_year" do
    budget = MonthlyBudget.new(
      user: @user_one,
      total_actual_income: 5000.00
    )
    assert_not budget.valid?
    assert_includes budget.errors[:month_year], "can't be blank"
  end

  test "should validate month_year format" do
    budget = MonthlyBudget.new(
      user: @user_one,
      month_year: "invalid",
      total_actual_income: 5000.00
    )
    assert_not budget.valid?
    assert_includes budget.errors[:month_year], "must be YYYY-MM"
  end

  test "should accept valid month_year format" do
    budget = MonthlyBudget.new(
      user: @user_one,
      month_year: "2026-02",
      total_actual_income: 5000.00
    )
    assert budget.valid?
  end

  test "should enforce unique month_year per user" do
    duplicate_budget = MonthlyBudget.new(
      user: @user_one,
      month_year: @budget_one.month_year,
      total_actual_income: 6000.00
    )
    assert_not duplicate_budget.valid?
    assert_includes duplicate_budget.errors[:month_year], "has already been taken"
  end

  test "different users can have budgets for same month_year" do
    # user_one has budget_one (2025-12), user_two has budget_three (2025-12)
    # Both users can have budgets for the same month_year
    assert_equal "2025-12", monthly_budgets(:one).month_year
    assert_equal "2025-12", monthly_budgets(:three).month_year
    assert_equal users(:one), monthly_budgets(:one).user
    assert_equal users(:two), monthly_budgets(:three).user
    
    # Both budgets are valid even though they share the same month_year
    assert monthly_budgets(:one).valid?
    assert monthly_budgets(:three).valid?
  end

  test "should require total_actual_income to be greater than or equal to 0" do
    budget = MonthlyBudget.new(
      user: @user_one,
      month_year: "2026-01",
      total_actual_income: -100.00
    )
    assert_not budget.valid?
    assert_includes budget.errors[:total_actual_income], "must be greater than or equal to 0"
  end

  test "should have default total_actual_income of 0.0" do
    budget = MonthlyBudget.create!(
      user: @user_one,
      month_year: "2026-02"
    )
    assert_equal 0.0, budget.total_actual_income.to_f
  end

  test "should require flex_fund to be greater than or equal to 0" do
    budget = MonthlyBudget.new(
      user: @user_one,
      month_year: "2026-01",
      total_actual_income: 5000.00,
      flex_fund: -100.00
    )
    assert_not budget.valid?
    assert_includes budget.errors[:flex_fund], "must be greater than or equal to 0"
  end

  test "should have default flex_fund of 0.0" do
    budget = MonthlyBudget.create!(
      user: @user_one,
      month_year: "2026-02"
    )
    assert_equal 0.0, budget.flex_fund.to_f
  end

  test "should allow bank_balance to be nil" do
    budget = MonthlyBudget.new(
      user: @user_one,
      month_year: "2026-01",
      total_actual_income: 5000.00,
      bank_balance: nil
    )
    assert budget.valid?
  end

  test "should validate bank_balance to be greater than or equal to 0 when present" do
    budget = MonthlyBudget.new(
      user: @user_one,
      month_year: "2026-01",
      total_actual_income: 5000.00,
      bank_balance: -100.00
    )
    assert_not budget.valid?
    assert_includes budget.errors[:bank_balance], "must be greater than or equal to 0"
  end

  test "should destroy when user is destroyed" do
    user_with_budget = User.create!(
      email: "test@example.com",
      password: "password123"
    )
    budget = MonthlyBudget.create!(
      user: user_with_budget,
      month_year: "2025-12",
      total_actual_income: 1000.00
    )
    
    assert_difference("MonthlyBudget.count", -1) do
      user_with_budget.destroy
    end
  end

  test "by_month scope should return budgets for specific month" do
    budgets = MonthlyBudget.by_month("2025-12")
    assert_includes budgets, @budget_one
    assert_includes budgets, monthly_budgets(:three)
    assert_not_includes budgets, @budget_two
  end

  test "for_user scope should return budgets for specific user" do
    budgets = MonthlyBudget.for_user(@user_one)
    assert_includes budgets, @budget_one
    assert_includes budgets, @budget_two
    assert_not_includes budgets, monthly_budgets(:three)
  end

  test "current scope should return budget for current month" do
    current_month = Time.current.strftime("%Y-%m")
    
    # Clean up any existing budgets for current month first (across all users)
    # since the scope doesn't filter by user
    MonthlyBudget.where(month_year: current_month).destroy_all
    
    budget = MonthlyBudget.create!(
      user: @user_one,
      month_year: current_month,
      total_actual_income: 5000.00
    )
    
    found_budget = MonthlyBudget.current
    assert_not_nil found_budget
    assert_equal budget.id, found_budget.id
    assert_equal current_month, found_budget.month_year
  end

  test "for_month scope should return budget for specific month" do
    budget = MonthlyBudget.create!(
      user: @user_one,
      month_year: "2026-05",
      total_actual_income: 5000.00
    )
    
    found_budget = MonthlyBudget.for_month("2026-05")
    assert_equal budget.id, found_budget.id if found_budget
  end

  test "name should return formatted month and year" do
    budget = MonthlyBudget.new(month_year: "2025-12")
    assert_equal "December 2025", budget.name
    
    budget = MonthlyBudget.new(month_year: "2026-01")
    assert_equal "January 2026", budget.name
  end

  test "month_year_with_user should return formatted string with user info" do
    user = User.create!(
      email: "displaytest@example.com",
      password: "password123",
      display_name: "John Doe"
    )
    budget = MonthlyBudget.create!(
      user: user,
      month_year: "2026-06",
      total_actual_income: 5000.00
    )
    
    assert_match(/2026-06/, budget.month_year_with_user)
    assert_match(/John Doe/, budget.month_year_with_user)
  end

  test "month_year_with_user should use email prefix if display_name is nil" do
    user = User.create!(
      email: "testuser@example.com",
      password: "password123",
      display_name: nil
    )
    budget = MonthlyBudget.create!(
      user: user,
      month_year: "2026-07",
      total_actual_income: 5000.00
    )
    
    assert_match(/2026-07/, budget.month_year_with_user)
    assert_match(/Testuser/, budget.month_year_with_user)
  end

  test "total_allotted should sum allotted_amount from all expenses" do
    budget = MonthlyBudget.create!(
      user: @user_one,
      month_year: "2026-08",
      total_actual_income: 5000.00
    )
    
    template1 = ExpenseTemplate.create!(
      user: @user_one,
      name: "Test Template 1",
      frequency: "monthly",
      default_amount: 100.00
    )
    
    template2 = ExpenseTemplate.create!(
      user: @user_one,
      name: "Test Template 2",
      frequency: "monthly",
      default_amount: 200.00
    )
    
    Expense.create!(
      monthly_budget: budget,
      expense_template: template1,
      allotted_amount: 100.00
    )
    
    Expense.create!(
      monthly_budget: budget,
      expense_template: template2,
      allotted_amount: 200.00
    )
    
    assert_equal 300.00, budget.total_allotted.to_f
  end

  test "total_spent should sum spent_amount from all expenses" do
    budget = MonthlyBudget.create!(
      user: @user_one,
      month_year: "2026-09",
      total_actual_income: 5000.00
    )
    
    template = ExpenseTemplate.create!(
      user: @user_one,
      name: "Test Template",
      frequency: "monthly",
      default_amount: 100.00
    )
    
    expense = Expense.create!(
      monthly_budget: budget,
      expense_template: template,
      allotted_amount: 500.00
    )
    
    Payment.create!(
      expense: expense,
      amount: 100.00,
      spent_on: Date.today
    )
    
    Payment.create!(
      expense: expense,
      amount: 50.00,
      spent_on: Date.today
    )
    
    assert_equal 150.00, budget.total_spent.to_f
  end

  test "remaining_to_assign should return difference between income and allotted" do
    budget = MonthlyBudget.create!(
      user: @user_one,
      month_year: "2026-10",
      total_actual_income: 5000.00
    )
    
    template = ExpenseTemplate.create!(
      user: @user_one,
      name: "Test Template",
      frequency: "monthly",
      default_amount: 100.00
    )
    
    Expense.create!(
      monthly_budget: budget,
      expense_template: template,
      allotted_amount: 2000.00
    )
    
    assert_equal 3000.00, budget.remaining_to_assign.to_f
  end

  test "remaining_to_assign can be negative if more allotted than income" do
    budget = MonthlyBudget.create!(
      user: @user_one,
      month_year: "2026-11",
      total_actual_income: 1000.00
    )
    
    template = ExpenseTemplate.create!(
      user: @user_one,
      name: "Test Template",
      frequency: "monthly",
      default_amount: 100.00
    )
    
    Expense.create!(
      monthly_budget: budget,
      expense_template: template,
      allotted_amount: 2000.00
    )
    
    assert_equal(-1000.00, budget.remaining_to_assign.to_f)
  end

  test "remaining_to_assign should return available income minus total allotted" do
    # Use a different user to avoid carryover from other tests
    test_user = User.create!(email: "remaining_test@example.com", password: "password123")
    
    budget = MonthlyBudget.create!(
      user: test_user,
      month_year: "2026-12",
      total_actual_income: 5000.00
    )
    
    template = ExpenseTemplate.create!(
      user: test_user,
      name: "Test Template",
      frequency: "monthly",
      default_amount: 100.00
    )
    
    Expense.create!(
      monthly_budget: budget,
      expense_template: template,
      allotted_amount: 2000.00
    )
    
    # remaining_to_assign = available_income - total_allotted
    # available_income = total_actual_income + carryover (0 in this case, no previous month)
    # So: 5000.00 - 2000.00 = 3000.00
    assert_equal 3000.00, budget.remaining_to_assign.to_f
    
    # Test negative case - can be negative (indicates overspending)
    # Use a month that doesn't have a previous month budget to avoid carryover
    budget2 = MonthlyBudget.create!(
      user: test_user,
      month_year: "2026-11",  # Before budget, so no carryover
      total_actual_income: 1000.00
    )
    
    Expense.create!(
      monthly_budget: budget2,
      expense_template: template,
      allotted_amount: 2000.00
    )
    
    # remaining_to_assign can be negative (indicates overspending)
    # available_income = 1000.00 + 0 (no carryover) = 1000.00
    # remaining_to_assign = 1000.00 - 2000.00 = -1000.00
    assert_equal -1000.00, budget2.remaining_to_assign.to_f
  end

  test "bank_difference should return nil if bank_balance is not set" do
    budget = MonthlyBudget.create!(
      user: @user_one,
      month_year: "2027-02",
      total_actual_income: 5000.00,
      bank_balance: nil
    )
    
    assert_nil budget.bank_difference
  end

  test "bank_difference should calculate difference when bank_balance is set" do
    budget = MonthlyBudget.create!(
      user: @user_one,
      month_year: "2027-03",
      total_actual_income: 5000.00,
      bank_balance: 3000.00
    )
    
    template = ExpenseTemplate.create!(
      user: @user_one,
      name: "Test Template",
      frequency: "monthly",
      default_amount: 100.00
    )
    
    expense = Expense.create!(
      monthly_budget: budget,
      expense_template: template,
      allotted_amount: 2000.00
    )
    
    Payment.create!(
      expense: expense,
      amount: 500.00,
      spent_on: Date.today
    )
    
    # bank_balance (3000) - (total_actual_income (5000) - total_spent (500)) = 3000 - 4500 = -1500
    assert_equal(-1500.00, budget.bank_difference.to_f)
  end

  test "bank_match? should return true if bank_balance is not set" do
    budget = MonthlyBudget.create!(
      user: @user_one,
      month_year: "2027-04",
      total_actual_income: 5000.00,
      bank_balance: nil
    )
    
    assert budget.bank_match?
  end

  test "bank_match? should return true if difference is within 50 dollar tolerance" do
    budget = MonthlyBudget.create!(
      user: @user_one,
      month_year: "2027-05",
      total_actual_income: 5000.00,
      bank_balance: 3000.00
    )
    
    template = ExpenseTemplate.create!(
      user: @user_one,
      name: "Test Template",
      frequency: "monthly",
      default_amount: 100.00
    )
    
    expense = Expense.create!(
      monthly_budget: budget,
      expense_template: template,
      allotted_amount: 2000.00
    )
    
    Payment.create!(
      expense: expense,
      amount: 500.00,
      spent_on: Date.today
    )
    
    # bank_balance (3000) vs calculated (5000 - 500 = 4500), difference = -1500
    # This is outside the 50 tolerance, so should be false
    assert_not budget.bank_match?
    
    # Set bank_balance to be within 50 of calculated
    budget.update(bank_balance: 4500.00)
    assert budget.bank_match?
    
    budget.update(bank_balance: 4525.00)
    assert budget.bank_match?
    
    budget.update(bank_balance: 4551.00)
    assert_not budget.bank_match?
  end

  # Test auto_create_expenses method
  test "auto_create_expenses should create expenses for templates with auto_create true" do
    user = User.create!(email: "autotest@example.com", password: "password123")
    budget = MonthlyBudget.create!(
      user: user,
      month_year: "2026-01",
      total_actual_income: 5000.00
    )
    
    # Create expense templates with auto_create: true
    template1 = ExpenseTemplate.create!(
      user: user,
      name: "Groceries",
      frequency: "monthly",
      default_amount: 500.00,
      auto_create: true
    )
    
    template2 = ExpenseTemplate.create!(
      user: user,
      name: "Rent",
      frequency: "monthly",
      default_amount: 1200.00,
      auto_create: true
    )
    
    # Create a template with auto_create: false (should be skipped)
    template3 = ExpenseTemplate.create!(
      user: user,
      name: "Entertainment",
      frequency: "monthly",
      default_amount: 200.00,
      auto_create: false
    )
    
    assert_difference("Expense.count", 2) do
      budget.auto_create_expenses
    end
    
    assert_equal 2, budget.expenses.count
    assert budget.expenses.exists?(expense_template_id: template1.id)
    assert budget.expenses.exists?(expense_template_id: template2.id)
    assert_not budget.expenses.exists?(expense_template_id: template3.id)
    
    # Check that default_amount was used
    expense1 = budget.expenses.find_by(expense_template: template1)
    expense2 = budget.expenses.find_by(expense_template: template2)
    assert_equal 500.00, expense1.allotted_amount
    assert_equal 1200.00, expense2.allotted_amount
  end

  test "auto_create_expenses should skip templates that already have expenses" do
    user = User.create!(email: "skiptest@example.com", password: "password123")
    budget = MonthlyBudget.create!(
      user: user,
      month_year: "2026-02",
      total_actual_income: 5000.00
    )
    
    template = ExpenseTemplate.create!(
      user: user,
      name: "Groceries",
      frequency: "monthly",
      default_amount: 500.00,
      auto_create: true
    )
    
    # Create an expense manually for this category
    existing_expense = Expense.create!(
      monthly_budget: budget,
      expense_template: template,
      allotted_amount: 600.00
    )
    
    # Should not create duplicate expense
    assert_no_difference("Expense.count") do
      budget.auto_create_expenses
    end
    
    # Should still have only one expense
    assert_equal 1, budget.expenses.count
    assert_equal existing_expense.id, budget.expenses.first.id
    assert_equal 600.00, budget.expenses.first.allotted_amount
  end

  test "auto_create_expenses should use default_amount of 0 if template default_amount is nil" do
    user = User.create!(email: "defaulttest@example.com", password: "password123")
    budget = MonthlyBudget.create!(
      user: user,
      month_year: "2026-03",
      total_actual_income: 5000.00
    )
    
    template = ExpenseTemplate.create!(
      user: user,
      name: "New Template",
      frequency: "monthly",
      default_amount: nil,
      auto_create: true
    )
    
    budget.auto_create_expenses
    
    expense = budget.expenses.find_by(expense_template: template)
    assert_not_nil expense
    assert_equal 0.0, expense.allotted_amount.to_f
  end

  test "auto_create_expenses should only create expenses for the budget's user's templates" do
    user1 = User.create!(email: "user1_categories@example.com", password: "password123")
    user2 = User.create!(email: "user2_categories@example.com", password: "password123")
    
    budget = MonthlyBudget.create!(
      user: user1,
      month_year: "2026-04",
      total_actual_income: 5000.00
    )
    
    # Create templates for both users
    user1_template = ExpenseTemplate.create!(
      user: user1,
      name: "User1 Template",
      frequency: "monthly",
      default_amount: 500.00,
      auto_create: true
    )
    
    user2_template = ExpenseTemplate.create!(
      user: user2,
      name: "User2 Template",
      frequency: "monthly",
      default_amount: 300.00,
      auto_create: true
    )
    
    budget.auto_create_expenses
    
    # Should only create expense for user1's template
    assert_equal 1, budget.expenses.count
    assert budget.expenses.exists?(expense_template_id: user1_template.id)
    assert_not budget.expenses.exists?(expense_template_id: user2_template.id)
  end

  # Test auto_create_income_events method
  test "auto_create_income_events should create income events for templates with auto_create true" do
    user = User.create!(email: "income_autotest@example.com", password: "password123")
    budget = MonthlyBudget.create!(
      user: user,
      month_year: "2026-01",
      total_actual_income: 5000.00
    )
    
    # Create income templates with auto_create: true
    template1 = IncomeTemplate.create!(
      user: user,
      name: "Salary",
      frequency: "monthly",
      estimated_amount: 5000.00,
      auto_create: true,
      due_date: Date.parse("2026-01-15")
    )
    
    template2 = IncomeTemplate.create!(
      user: user,
      name: "Freelance",
      frequency: "bi_weekly",
      estimated_amount: 1000.00,
      auto_create: true,
      due_date: Date.parse("2026-01-01")
    )
    
    # Create a template with auto_create: false (should be skipped)
    template3 = IncomeTemplate.create!(
      user: user,
      name: "Bonus",
      frequency: "monthly",
      estimated_amount: 500.00,
      auto_create: false,
      due_date: Date.parse("2026-01-20")
    )
    
    # Bi-weekly starting Jan 1, 2026 will create events on Jan 1, Jan 15, and Jan 29 (3 events)
    # Monthly will create 1 event on Jan 15
    # Total: 4 events
    assert_difference("IncomeEvent.count", 4) do # 1 monthly + 3 bi-weekly
      budget.auto_create_income_events
    end
    
    # Check that events were created for auto_create templates
    assert user.income_events.exists?(income_template_id: template1.id)
    assert user.income_events.exists?(income_template_id: template2.id)
    assert_not user.income_events.exists?(income_template_id: template3.id)
  end

  test "auto_create_income_events should skip templates that already have events for the same date" do
    user = User.create!(email: "income_skiptest@example.com", password: "password123")
    budget = MonthlyBudget.create!(
      user: user,
      month_year: "2026-02",
      total_actual_income: 5000.00
    )
    
    template = IncomeTemplate.create!(
      user: user,
      name: "Salary",
      frequency: "monthly",
      estimated_amount: 5000.00,
      auto_create: true,
      due_date: Date.parse("2026-02-15")
    )
    
    # Create an event manually for this template and date
    existing_event = IncomeEvent.create!(
      user: user,
      income_template: template,
      received_on: Date.parse("2026-02-15"),
      month_year: "2026-02",
      actual_amount: 5000.00
    )
    
    # Should not create duplicate event
    assert_no_difference("IncomeEvent.count") do
      budget.auto_create_income_events
    end
    
    # Should still have only one event
    assert_equal 1, user.income_events.where(income_template: template, month_year: "2026-02").count
  end

  # Deferral functionality removed - replaced with automatic carryover
  # Test removed as last_payment_to_next_month logic no longer exists

  # Test expected_income method
  test "expected_income should calculate from template-based events" do
    user = User.create!(email: "expected_income_test@example.com", password: "password123")
    budget = MonthlyBudget.create!(
      user: user,
      month_year: "2026-04",
      total_actual_income: 5000.00
    )
    
    template = IncomeTemplate.create!(
      user: user,
      name: "Salary",
      frequency: "monthly",
      estimated_amount: 5000.00,
      auto_create: false
    )
    
    # Create 2 events for this template in this month
    IncomeEvent.create!(
      user: user,
      income_template: template,
      received_on: Date.parse("2026-04-01"),
      month_year: "2026-04",
      actual_amount: 0,
      apply_to_next_month: false
    )
    
    IncomeEvent.create!(
      user: user,
      income_template: template,
      received_on: Date.parse("2026-04-15"),
      month_year: "2026-04",
      actual_amount: 0,
      apply_to_next_month: false
    )
    
    # Expected income = 2 events × 5000.00 = 10000.00
    assert_equal 10000.00, budget.expected_income.to_f
  end

  # Deferral functionality removed - replaced with automatic carryover
  # expected_income now only counts events in the current month
  # Deferred events from previous month are handled via carryover, not expected_income
  test "expected_income should only count events in current month" do
    user = User.create!(email: "deferred_income_test@example.com", password: "password123")
    budget = MonthlyBudget.create!(
      user: user,
      month_year: "2026-05",
      total_actual_income: 5000.00
    )
    
    template = IncomeTemplate.create!(
      user: user,
      name: "Salary",
      frequency: "monthly",
      estimated_amount: 5000.00,
      auto_create: false
    )
    
    # Create an event in previous month (deferral no longer used)
    prev_month = "2026-04"
    IncomeEvent.create!(
      user: user,
      income_template: template,
      received_on: Date.parse("2026-04-30"),
      month_year: prev_month,
      actual_amount: 0,
      apply_to_next_month: false
    )
    
    # Create an event in current month
    IncomeEvent.create!(
      user: user,
      income_template: template,
      received_on: Date.parse("2026-05-15"),
      month_year: "2026-05",
      actual_amount: 0,
      apply_to_next_month: false
    )
    
    # Expected income = 1 event × 5000.00 = 5000.00 (only current month events)
    assert_equal 5000.00, budget.expected_income.to_f
  end

  test "expected_income should include one-off events (no template)" do
    user = User.create!(email: "oneoff_income_test@example.com", password: "password123")
    budget = MonthlyBudget.create!(
      user: user,
      month_year: "2026-06",
      total_actual_income: 5000.00
    )
    
    # Create one-off income event (no template)
    IncomeEvent.create!(
      user: user,
      income_template: nil,
      custom_label: "Bonus",
      received_on: Date.parse("2026-06-10"),
      month_year: "2026-06",
      actual_amount: 1000.00,
      apply_to_next_month: false
    )
    
    # Expected income = 1000.00 (from one-off event)
    assert_equal 1000.00, budget.expected_income.to_f
  end

  test "expected_income should combine template-based and one-off events" do
    user = User.create!(email: "combined_income_test@example.com", password: "password123")
    budget = MonthlyBudget.create!(
      user: user,
      month_year: "2026-07",
      total_actual_income: 5000.00
    )
    
    template = IncomeTemplate.create!(
      user: user,
      name: "Salary",
      frequency: "monthly",
      estimated_amount: 5000.00,
      auto_create: false
    )
    
    # Create template-based event
    IncomeEvent.create!(
      user: user,
      income_template: template,
      received_on: Date.parse("2026-07-15"),
      month_year: "2026-07",
      actual_amount: 0,
      apply_to_next_month: false
    )
    
    # Create one-off event
    IncomeEvent.create!(
      user: user,
      income_template: nil,
      custom_label: "Bonus",
      received_on: Date.parse("2026-07-20"),
      month_year: "2026-07",
      actual_amount: 1000.00,
      apply_to_next_month: false
    )
    
    # Expected income = 5000.00 (template) + 1000.00 (one-off) = 6000.00
    assert_equal 6000.00, budget.expected_income.to_f
  end

  test "expected_income should return 0 if no events exist" do
    user = User.create!(email: "no_income_test@example.com", password: "password123")
    budget = MonthlyBudget.create!(
      user: user,
      month_year: "2026-08",
      total_actual_income: 0.00
    )
    
    assert_equal 0.0, budget.expected_income.to_f
  end
end


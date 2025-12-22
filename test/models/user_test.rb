require "test_helper"

class UserTest < ActiveSupport::TestCase
  # Test fixtures
  test "should have valid fixtures" do
    assert users(:one).valid?
    assert users(:two).valid?
  end

  # Test display_name attribute
  test "should save display_name" do
    user = User.new(email: "test@example.com", password: "password123")
    user.display_name = "Test Display Name"
    assert user.save
    assert_equal "Test Display Name", user.display_name
  end

  test "display_name should be optional" do
    user = User.new(email: "test@example.com", password: "password123")
    assert user.save
    assert_nil user.display_name
  end

  # Test Devise email validation
  test "email should be present" do
    user = User.new(password: "password123")
    assert_not user.valid?
    assert_includes user.errors[:email], "can't be blank"
  end

  test "email should be unique" do
    existing_user = users(:one)
    user = User.new(email: existing_user.email, password: "password123")
    assert_not user.valid?
    assert_includes user.errors[:email], "has already been taken"
  end

  test "email should be properly formatted" do
    user = User.new(email: "invalid-email", password: "password123")
    assert_not user.valid?
    assert_includes user.errors[:email], "is invalid"
  end

  # Test Devise password validation
  test "password should be present" do
    user = User.new(email: "test@example.com")
    assert_not user.valid?
    assert_includes user.errors[:password], "can't be blank"
  end

  test "password should meet minimum length" do
    user = User.new(email: "test@example.com", password: "12345")
    assert_not user.valid?
    assert_includes user.errors[:password], "is too short (minimum is 6 characters)"
  end

  # Test Devise authentication
  test "should authenticate with valid credentials" do
    user = users(:one)
    authenticated_user = User.find_for_authentication(email: user.email)
    assert_equal user, authenticated_user
  end

  # Test Devise password confirmation
  test "password_confirmation should match password" do
    user = User.new(
      email: "test@example.com",
      password: "password123",
      password_confirmation: "different_password"
    )
    assert_not user.valid?
    assert_includes user.errors[:password_confirmation], "doesn't match Password"
  end

  # Test display_name edge cases
  test "display_name can be blank string" do
    user = User.new(email: "test@example.com", password: "password123", display_name: "")
    assert user.save
    assert_equal "", user.display_name
  end

  test "display_name can contain special characters" do
    user = User.new(email: "test@example.com", password: "password123", display_name: "John Doe 🎉")
    assert user.save
    assert_equal "John Doe 🎉", user.display_name
  end

  # Test uniqueness validation
  test "should validate email uniqueness" do
    # Email uniqueness is validated at model level by Devise
    user1 = User.create!(email: "unique@example.com", password: "password123")
    user2 = User.new(email: "unique@example.com", password: "password456")
    assert_not user2.valid?
    assert_includes user2.errors[:email], "has already been taken"
  end

  # Test current_budget method
  test "current_budget should return budget for current month" do
    user = User.create!(email: "current_budget@example.com", password: "password123")
    # Create a budget for current month
    current_month = Time.current.strftime("%Y-%m")
    budget = MonthlyBudget.create!(
      user: user,
      month_year: current_month,
      total_actual_income: 5000.00
    )
    
    assert_equal budget, user.current_budget
  end

  test "current_budget should return nil if no budget exists for current month" do
    user = User.create!(email: "newuser@example.com", password: "password123")
    assert_nil user.current_budget
  end

  # Test total_actual_savings_this_month method
  test "total_actual_savings_this_month should return 0 if no current budget" do
    user = User.create!(email: "savings_none@example.com", password: "password123")
    assert_equal 0, user.total_actual_savings_this_month
  end

  test "total_actual_savings_this_month should return 0 since savings tracking was removed" do
    user = User.create!(email: "savings_current@example.com", password: "password123")
    current_month = Time.current.strftime("%Y-%m")
    budget = MonthlyBudget.create!(
      user: user,
      month_year: current_month,
      total_actual_income: 5000.00
    )
    
    # Create an expense template
    template = ExpenseTemplate.create!(
      user: user,
      name: "Emergency Fund",
      frequency: "monthly",
      default_amount: 300.00,
      auto_create: false
    )
    
    # Create expense
    expense = Expense.create!(
      monthly_budget: budget,
      expense_template: template,
      name: template.name,
      allotted_amount: 300.00
    )
    
    # Create payment records
    Payment.create!(expense: expense, amount: 150.00, spent_on: Date.today)
    Payment.create!(expense: expense, amount: 50.00, spent_on: Date.today)
    
    # Returns 0 since savings scope was removed
    assert_equal 0, user.total_actual_savings_this_month
  end

  test "total_actual_savings_this_month should return 0 for multiple months since savings tracking was removed" do
    user = User.create!(email: "savings_multimonth@example.com", password: "password123")
    current_month = Time.current.strftime("%Y-%m")
    old_month = (Date.today - 1.month).strftime("%Y-%m")
    
    # Create current month budget
    current_budget = MonthlyBudget.create!(
      user: user,
      month_year: current_month,
      total_actual_income: 5000.00
    )
    
    # Create old month budget
    old_budget = MonthlyBudget.create!(
      user: user,
      month_year: old_month,
      total_actual_income: 4500.00
    )
    
    template = ExpenseTemplate.create!(
      user: user,
      name: "Emergency Fund",
      frequency: "monthly",
      default_amount: 300.00,
      auto_create: false
    )
    
    current_expense = Expense.create!(
      monthly_budget: current_budget,
      expense_template: template,
      name: template.name,
      allotted_amount: 300.00
    )
    
    old_expense = Expense.create!(
      monthly_budget: old_budget,
      expense_template: template,
      name: template.name,
      allotted_amount: 300.00
    )
    
    Payment.create!(expense: current_expense, amount: 100.00, spent_on: Date.today)
    Payment.create!(expense: old_expense, amount: 200.00, spent_on: Date.today - 1.month)
    
    # Returns 0 since savings scope was removed
    assert_equal 0, user.total_actual_savings_this_month
  end

  # Test total_actual_savings_all_time method
  test "total_actual_savings_all_time should return 0 since savings tracking was removed" do
    user = User.create!(email: "total_savings_all@example.com", password: "password123")
    
    # Create budgets for different months
    budget1 = MonthlyBudget.create!(
      user: user,
      month_year: "2026-12",
      total_actual_income: 5000.00
    )
    
    budget2 = MonthlyBudget.create!(
      user: user,
      month_year: "2026-11",
      total_actual_income: 4500.00
    )
    
    template = ExpenseTemplate.create!(
      user: user,
      name: "Emergency Fund",
      frequency: "monthly",
      default_amount: 300.00,
      auto_create: false
    )
    
    expense1 = Expense.create!(
      monthly_budget: budget1,
      expense_template: template,
      name: template.name,
      allotted_amount: 300.00
    )
    
    expense2 = Expense.create!(
      monthly_budget: budget2,
      expense_template: template,
      name: template.name,
      allotted_amount: 300.00
    )
    
    Payment.create!(expense: expense1, amount: 150.00, spent_on: Date.today)
    Payment.create!(expense: expense1, amount: 50.00, spent_on: Date.today)
    Payment.create!(expense: expense2, amount: 100.00, spent_on: Date.today - 1.month)
    
    # Returns 0 since savings scope was removed
    assert_equal 0, user.total_actual_savings_all_time
    assert_equal 0, user.total_savings  # Alias should work
  end

  # Test create_next_month_budget! method
  test "create_next_month_budget! should create budget for next month" do
    user = User.create!(email: "next_month_budget@example.com", password: "password123")
    next_month = (Date.today + 1.month).strftime("%Y-%m")
    
    # Create expense template with auto_create: true
    template = ExpenseTemplate.create!(
      user: user,
      name: "Next Month Groceries",
      frequency: "monthly",
      default_amount: 500.00,
      auto_create: true,
      due_date: Date.parse("#{next_month}-15")  # Need due_date for events_for_month
    )
    
    budget = user.create_next_month_budget!
    
    assert_not_nil budget
    assert_equal next_month, budget.month_year
    assert_equal 1, budget.expenses.count
    assert_equal template.id, budget.expenses.first.expense_template_id
  end

  test "create_next_month_budget! should return nil if budget already exists" do
    user = User.create!(email: "next_month_exists@example.com", password: "password123")
    next_month = (Date.today + 1.month).strftime("%Y-%m")
    
    existing_budget = MonthlyBudget.create!(
      user: user,
      month_year: next_month,
      total_actual_income: 5000.00
    )
    
    result = user.create_next_month_budget!
    assert_nil result
    # Should still have only one budget for next month
    assert_equal 1, MonthlyBudget.where(user: user, month_year: next_month).count
  end

  test "total_actual_savings_all_time should return 0 for mixed expenses since savings tracking was removed" do
    user = User.create!(email: "total_savings_only@example.com", password: "password123")
    
    budget = MonthlyBudget.create!(
      user: user,
      month_year: "2026-12",
      total_actual_income: 5000.00
    )
    
    template1 = ExpenseTemplate.create!(
      user: user,
      name: "Emergency Fund",
      frequency: "monthly",
      default_amount: 300.00,
      auto_create: false
    )
    
    template2 = ExpenseTemplate.create!(
      user: user,
      name: "Groceries",
      frequency: "monthly",
      default_amount: 500.00,
      auto_create: false
    )
    
    expense1 = Expense.create!(
      monthly_budget: budget,
      expense_template: template1,
      name: template1.name,
      allotted_amount: 300.00
    )
    
    expense2 = Expense.create!(
      monthly_budget: budget,
      expense_template: template2,
      name: template2.name,
      allotted_amount: 500.00
    )
    
    Payment.create!(expense: expense1, amount: 200.00, spent_on: Date.today)
    Payment.create!(expense: expense2, amount: 300.00, spent_on: Date.today)
    
    # Returns 0 since savings scope was removed
    assert_equal 0, user.total_actual_savings_all_time
    assert_equal 0, user.total_savings  # Alias should work
  end
end

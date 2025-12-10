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
    assert_includes budget.errors[:month_year], "must be in YYYY-MM format"
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
    assert_includes duplicate_budget.errors[:month_year], "already has a budget for this month"
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
end


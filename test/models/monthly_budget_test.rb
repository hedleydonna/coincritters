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

  test "total_allotted should sum allotted_amount from all envelopes" do
    budget = MonthlyBudget.create!(
      user: @user_one,
      month_year: "2026-08",
      total_actual_income: 5000.00
    )
    
    template1 = EnvelopeTemplate.create!(
      user: @user_one,
      name: "Test Template 1",
      group_type: :variable,
      default_amount: 100.00
    )
    
    template2 = EnvelopeTemplate.create!(
      user: @user_one,
      name: "Test Template 2",
      group_type: :variable,
      default_amount: 200.00
    )
    
    Envelope.create!(
      monthly_budget: budget,
      envelope_template: template1,
      allotted_amount: 100.00
    )
    
    Envelope.create!(
      monthly_budget: budget,
      envelope_template: template2,
      allotted_amount: 200.00
    )
    
    assert_equal 300.00, budget.total_allotted.to_f
  end

  test "total_spent should sum spent_amount from all envelopes" do
    budget = MonthlyBudget.create!(
      user: @user_one,
      month_year: "2026-09",
      total_actual_income: 5000.00
    )
    
    template = EnvelopeTemplate.create!(
      user: @user_one,
      name: "Test Template",
      group_type: :variable,
      default_amount: 100.00
    )
    
    envelope = Envelope.create!(
      monthly_budget: budget,
      envelope_template: template,
      allotted_amount: 500.00
    )
    
    Spending.create!(
      envelope: envelope,
      amount: 100.00,
      spent_on: Date.today
    )
    
    Spending.create!(
      envelope: envelope,
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
    
    template = EnvelopeTemplate.create!(
      user: @user_one,
      name: "Test Template",
      group_type: :variable,
      default_amount: 100.00
    )
    
    Envelope.create!(
      monthly_budget: budget,
      envelope_template: template,
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
    
    template = EnvelopeTemplate.create!(
      user: @user_one,
      name: "Test Template",
      group_type: :variable,
      default_amount: 100.00
    )
    
    Envelope.create!(
      monthly_budget: budget,
      envelope_template: template,
      allotted_amount: 2000.00
    )
    
    assert_equal(-1000.00, budget.remaining_to_assign.to_f)
  end

  test "unassigned should return remaining_to_assign but never negative" do
    budget = MonthlyBudget.create!(
      user: @user_one,
      month_year: "2026-12",
      total_actual_income: 5000.00
    )
    
    template = EnvelopeTemplate.create!(
      user: @user_one,
      name: "Test Template",
      group_type: :variable,
      default_amount: 100.00
    )
    
    Envelope.create!(
      monthly_budget: budget,
      envelope_template: template,
      allotted_amount: 2000.00
    )
    
    assert_equal 3000.00, budget.unassigned.to_f
    
    # Test negative case
    budget2 = MonthlyBudget.create!(
      user: @user_one,
      month_year: "2027-01",
      total_actual_income: 1000.00
    )
    
    Envelope.create!(
      monthly_budget: budget2,
      envelope_template: template,
      allotted_amount: 2000.00
    )
    
    assert_equal 0.0, budget2.unassigned.to_f
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
    
    template = EnvelopeTemplate.create!(
      user: @user_one,
      name: "Test Template",
      group_type: :variable,
      default_amount: 100.00
    )
    
    envelope = Envelope.create!(
      monthly_budget: budget,
      envelope_template: template,
      allotted_amount: 2000.00
    )
    
    Spending.create!(
      envelope: envelope,
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
    
    template = EnvelopeTemplate.create!(
      user: @user_one,
      name: "Test Template",
      group_type: :variable,
      default_amount: 100.00
    )
    
    envelope = Envelope.create!(
      monthly_budget: budget,
      envelope_template: template,
      allotted_amount: 2000.00
    )
    
    Spending.create!(
      envelope: envelope,
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

  # Test auto_create_envelopes method
  test "auto_create_envelopes should create envelopes for categories with auto_create true" do
    user = User.create!(email: "autotest@example.com", password: "password123")
    budget = MonthlyBudget.create!(
      user: user,
      month_year: "2026-01",
      total_actual_income: 5000.00
    )
    
    # Create envelope templates with auto_create: true
    template1 = EnvelopeTemplate.create!(
      user: user,
      name: "Groceries",
      group_type: :variable,
      is_savings: false,
      default_amount: 500.00,
      auto_create: true
    )
    
    template2 = EnvelopeTemplate.create!(
      user: user,
      name: "Rent",
      group_type: :fixed,
      is_savings: false,
      default_amount: 1200.00,
      auto_create: true
    )
    
    # Create a template with auto_create: false (should be skipped)
    template3 = EnvelopeTemplate.create!(
      user: user,
      name: "Entertainment",
      group_type: :variable,
      is_savings: false,
      default_amount: 200.00,
      auto_create: false
    )
    
    assert_difference("Envelope.count", 2) do
      budget.auto_create_envelopes
    end
    
    assert_equal 2, budget.envelopes.count
    assert budget.envelopes.exists?(envelope_template_id: template1.id)
    assert budget.envelopes.exists?(envelope_template_id: template2.id)
    assert_not budget.envelopes.exists?(envelope_template_id: template3.id)
    
    # Check that default_amount was used
    envelope1 = budget.envelopes.find_by(envelope_template: template1)
    envelope2 = budget.envelopes.find_by(envelope_template: template2)
    assert_equal 500.00, envelope1.allotted_amount
    assert_equal 1200.00, envelope2.allotted_amount
  end

  test "auto_create_envelopes should skip categories that already have envelopes" do
    user = User.create!(email: "skiptest@example.com", password: "password123")
    budget = MonthlyBudget.create!(
      user: user,
      month_year: "2026-02",
      total_actual_income: 5000.00
    )
    
    template = EnvelopeTemplate.create!(
      user: user,
      name: "Groceries",
      group_type: :variable,
      is_savings: false,
      default_amount: 500.00,
      auto_create: true
    )
    
    # Create an envelope manually for this category
    existing_envelope = Envelope.create!(
      monthly_budget: budget,
      envelope_template: template,
      allotted_amount: 600.00
    )
    
    # Should not create duplicate envelope
    assert_no_difference("Envelope.count") do
      budget.auto_create_envelopes
    end
    
    # Should still have only one envelope
    assert_equal 1, budget.envelopes.count
    assert_equal existing_envelope.id, budget.envelopes.first.id
    assert_equal 600.00, budget.envelopes.first.allotted_amount
  end

  test "auto_create_envelopes should use default_amount of 0 if template default_amount is nil" do
    user = User.create!(email: "defaulttest@example.com", password: "password123")
    budget = MonthlyBudget.create!(
      user: user,
      month_year: "2026-03",
      total_actual_income: 5000.00
    )
    
    template = EnvelopeTemplate.create!(
      user: user,
      name: "New Template",
      group_type: :variable,
      is_savings: false,
      default_amount: nil,
      auto_create: true
    )
    
    budget.auto_create_envelopes
    
    envelope = budget.envelopes.find_by(envelope_template: template)
    assert_not_nil envelope
    assert_equal 0.0, envelope.allotted_amount.to_f
  end

  test "auto_create_envelopes should only create envelopes for the budget's user's categories" do
    user1 = User.create!(email: "user1_categories@example.com", password: "password123")
    user2 = User.create!(email: "user2_categories@example.com", password: "password123")
    
    budget = MonthlyBudget.create!(
      user: user1,
      month_year: "2026-04",
      total_actual_income: 5000.00
    )
    
    # Create templates for both users
    user1_template = EnvelopeTemplate.create!(
      user: user1,
      name: "User1 Template",
      group_type: :variable,
      is_savings: false,
      default_amount: 500.00,
      auto_create: true
    )
    
    user2_template = EnvelopeTemplate.create!(
      user: user2,
      name: "User2 Template",
      group_type: :variable,
      is_savings: false,
      default_amount: 300.00,
      auto_create: true
    )
    
    budget.auto_create_envelopes
    
    # Should only create envelope for user1's template
    assert_equal 1, budget.envelopes.count
    assert budget.envelopes.exists?(envelope_template_id: user1_template.id)
    assert_not budget.envelopes.exists?(envelope_template_id: user2_template.id)
  end
end


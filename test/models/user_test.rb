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

  test "total_actual_savings_this_month should sum spent_amount from savings envelopes in current budget" do
    user = User.create!(email: "savings_current@example.com", password: "password123")
    current_month = Time.current.strftime("%Y-%m")
    budget = MonthlyBudget.create!(
      user: user,
      month_year: current_month,
      total_actual_income: 5000.00
    )
    
    # Create a savings envelope template
    savings_template = EnvelopeTemplate.create!(
      user: user,
      name: "Emergency Fund",
      group_type: :fixed,
      is_savings: true,
      default_amount: 300.00,
      auto_create: false
    )
    
    # Create envelope with savings template
    envelope = Envelope.create!(
      monthly_budget: budget,
      envelope_template: savings_template,
      allotted_amount: 300.00
    )
    
    # Create spending records
    Spending.create!(envelope: envelope, amount: 150.00, spent_on: Date.today)
    Spending.create!(envelope: envelope, amount: 50.00, spent_on: Date.today)
    
    assert_equal 200.00, user.total_actual_savings_this_month
  end

  test "total_actual_savings_this_month should only include savings envelopes from current budget" do
    user = User.create!(email: "savings_multimonth@example.com", password: "password123")
    current_month = Time.current.strftime("%Y-%m")
    old_month = (Date.today - 1.month).strftime("%Y-%m")
    
    # Create current month budget with savings
    current_budget = MonthlyBudget.create!(
      user: user,
      month_year: current_month,
      total_actual_income: 5000.00
    )
    
    # Create old month budget with savings
    old_budget = MonthlyBudget.create!(
      user: user,
      month_year: old_month,
      total_actual_income: 4500.00
    )
    
    savings_template = EnvelopeTemplate.create!(
      user: user,
      name: "Emergency Fund",
      group_type: :fixed,
      is_savings: true,
      default_amount: 300.00,
      auto_create: false
    )
    
    current_envelope = Envelope.create!(
      monthly_budget: current_budget,
      envelope_template: savings_template,
      allotted_amount: 300.00
    )
    
    old_envelope = Envelope.create!(
      monthly_budget: old_budget,
      envelope_template: savings_template,
      allotted_amount: 300.00
    )
    
    Spending.create!(envelope: current_envelope, amount: 100.00, spent_on: Date.today)
    Spending.create!(envelope: old_envelope, amount: 200.00, spent_on: Date.today - 1.month)
    
    # Should only include current month's savings
    assert_equal 100.00, user.total_actual_savings_this_month
  end

  # Test total_actual_savings_all_time method
  test "total_actual_savings_all_time should sum spent_amount from all savings envelopes across all months" do
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
    
    savings_template = EnvelopeTemplate.create!(
      user: user,
      name: "Emergency Fund",
      group_type: :fixed,
      is_savings: true,
      default_amount: 300.00,
      auto_create: false
    )
    
    envelope1 = Envelope.create!(
      monthly_budget: budget1,
      envelope_template: savings_template,
      allotted_amount: 300.00
    )
    
    envelope2 = Envelope.create!(
      monthly_budget: budget2,
      envelope_template: savings_template,
      allotted_amount: 300.00
    )
    
    Spending.create!(envelope: envelope1, amount: 150.00, spent_on: Date.today)
    Spending.create!(envelope: envelope1, amount: 50.00, spent_on: Date.today)
    Spending.create!(envelope: envelope2, amount: 100.00, spent_on: Date.today - 1.month)
    
    assert_equal 300.00, user.total_actual_savings_all_time
    assert_equal 300.00, user.total_savings  # Alias should work
  end

  # Test create_next_month_budget! method
  test "create_next_month_budget! should create budget for next month" do
    user = User.create!(email: "next_month_budget@example.com", password: "password123")
    next_month = (Date.today + 1.month).strftime("%Y-%m")
    
    # Create envelope template with auto_create: true
    template = EnvelopeTemplate.create!(
      user: user,
      name: "Next Month Groceries",
      group_type: :variable,
      is_savings: false,
      default_amount: 500.00,
      auto_create: true
    )
    
    budget = user.create_next_month_budget!
    
    assert_not_nil budget
    assert_equal next_month, budget.month_year
    assert_equal 1, budget.envelopes.count
    assert_equal template.id, budget.envelopes.first.envelope_template_id
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

  test "total_actual_savings_all_time should only include savings envelopes" do
    user = User.create!(email: "total_savings_only@example.com", password: "password123")
    
    budget = MonthlyBudget.create!(
      user: user,
      month_year: "2026-12",
      total_actual_income: 5000.00
    )
    
    savings_template = EnvelopeTemplate.create!(
      user: user,
      name: "Emergency Fund",
      group_type: :fixed,
      is_savings: true,
      default_amount: 300.00,
      auto_create: false
    )
    
    non_savings_template = EnvelopeTemplate.create!(
      user: user,
      name: "Groceries",
      group_type: :variable,
      is_savings: false,
      default_amount: 500.00,
      auto_create: false
    )
    
    savings_envelope = Envelope.create!(
      monthly_budget: budget,
      envelope_template: savings_template,
      allotted_amount: 300.00
    )
    
    non_savings_envelope = Envelope.create!(
      monthly_budget: budget,
      envelope_template: non_savings_template,
      allotted_amount: 500.00
    )
    
    Spending.create!(envelope: savings_envelope, amount: 200.00, spent_on: Date.today)
    Spending.create!(envelope: non_savings_envelope, amount: 300.00, spent_on: Date.today)
    
    # Should only include savings envelope spending
    assert_equal 200.00, user.total_actual_savings_all_time
    assert_equal 200.00, user.total_savings  # Alias should work
  end
end

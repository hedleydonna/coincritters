require "test_helper"

class IncomeEventTest < ActiveSupport::TestCase
  setup do
    @user_one = users(:one)
    @user_two = users(:two)
    @income_one = incomes(:one)
    @income_event_one = income_events(:one)
  end

  test "should be valid with valid attributes" do
    income_event = IncomeEvent.new(
      user: @user_one,
      income: @income_one,
      custom_label: "Paycheck",
      month_year: "2025-12",
      received_on: Date.today,
      actual_amount: 1000.00
    )
    assert income_event.valid?
  end

  test "should require a user" do
    income_event = IncomeEvent.new(
      income: @income_one,
      custom_label: "Paycheck",
      month_year: "2025-12",
      received_on: Date.today
    )
    assert_not income_event.valid?
    assert_includes income_event.errors[:user], "must exist"
  end

  test "should require custom_label if income_id is nil" do
    income_event = IncomeEvent.new(
      user: @user_one,
      income: nil,  # No income, so custom_label is required
      month_year: "2025-12",
      received_on: Date.today,
      custom_label: nil  # Explicitly set to nil to test validation
    )
    assert_not income_event.valid?
    assert_includes income_event.errors[:custom_label], "can't be blank"
  end

  test "should not require custom_label if income_id is present" do
    income_event = IncomeEvent.new(
      user: @user_one,
      income: @income_one,  # Income present, so custom_label is optional
      month_year: "2025-12",
      received_on: Date.today,
      custom_label: nil  # Can be nil when income is present
    )
    assert income_event.valid?
  end

  test "should allow income to be optional" do
    income_event = IncomeEvent.new(
      user: @user_one,
      custom_label: "Bonus",
      month_year: "2025-12",
      received_on: Date.today,
      actual_amount: 500.00
    )
    assert income_event.valid?
  end

  test "should require month_year" do
    income_event = IncomeEvent.new(
      user: @user_one,
      custom_label: "Paycheck",
      received_on: Date.today
    )
    assert_not income_event.valid?
    assert_includes income_event.errors[:month_year], "can't be blank"
  end

  test "should validate month_year format" do
    income_event = IncomeEvent.new(
      user: @user_one,
      custom_label: "Paycheck",
      month_year: "invalid",
      received_on: Date.today
    )
    assert_not income_event.valid?
    assert_includes income_event.errors[:month_year], "must be in YYYY-MM format"
  end

  test "should accept valid month_year format" do
    income_event = IncomeEvent.new(
      user: @user_one,
      custom_label: "Paycheck",
      month_year: "2025-12",
      received_on: Date.today,
      actual_amount: 1000.00
    )
    assert income_event.valid?
  end

  test "should validate assigned_month_year format when present" do
    income_event = IncomeEvent.new(
      user: @user_one,
      custom_label: "Paycheck",
      month_year: "2025-12",
      assigned_month_year: "invalid",
      received_on: Date.today
    )
    assert_not income_event.valid?
    assert_includes income_event.errors[:assigned_month_year], "must be in YYYY-MM format"
  end

  test "should allow assigned_month_year to be blank" do
    income_event = IncomeEvent.new(
      user: @user_one,
      custom_label: "Paycheck",
      month_year: "2025-12",
      received_on: Date.today,
      actual_amount: 1000.00
    )
    assert income_event.valid?
  end

  test "should require received_on" do
    income_event = IncomeEvent.new(
      user: @user_one,
      custom_label: "Paycheck",
      month_year: "2025-12"
    )
    assert_not income_event.valid?
    assert_includes income_event.errors[:received_on], "can't be blank"
  end

  test "should require actual_amount to be greater than or equal to 0" do
    income_event = IncomeEvent.new(
      user: @user_one,
      custom_label: "Paycheck",
      month_year: "2025-12",
      received_on: Date.today,
      actual_amount: -100.00
    )
    assert_not income_event.valid?
    assert_includes income_event.errors[:actual_amount], "must be greater than or equal to 0"
  end

  test "should have default actual_amount of 0.0" do
    income_event = IncomeEvent.create!(
      user: @user_one,
      custom_label: "Paycheck",
      month_year: "2025-12",
      received_on: Date.today
    )
    assert_equal 0.0, income_event.actual_amount.to_f
  end


  test "should destroy when user is destroyed" do
    user_with_event = User.create!(
      email: "test@example.com",
      password: "password123"
    )
    income_event = IncomeEvent.create!(
      user: user_with_event,
      custom_label: "Bonus",
      month_year: "2025-12",
      received_on: Date.today
    )
    
    # When a user is deleted, their income_events are cascade deleted
    assert_difference("IncomeEvent.count", -1) do
      user_with_event.destroy
    end
    
    # Verify the event no longer exists
    assert_not IncomeEvent.exists?(income_event.id)
  end

  test "should destroy when income is destroyed" do
    # Create a new income for this test to avoid fixture interference
    new_income = Income.create!(
      user: @user_one,
      name: "Test Income",
      frequency: "monthly",
      estimated_amount: 1000.00
    )
    income_event = IncomeEvent.create!(
      user: @user_one,
      income: new_income,
      custom_label: "Paycheck",
      month_year: "2025-12",
      received_on: Date.today
    )
    
    assert_difference("IncomeEvent.count", -1) do
      new_income.destroy
    end
  end

  test "custom_label can be any string value" do
    income_event = IncomeEvent.new(
      user: @user_one,
      custom_label: "Custom Type Name",
      month_year: "2025-12",
      received_on: Date.today,
      actual_amount: 1000.00
    )
    assert income_event.valid?
    assert income_event.save
    assert_equal "Custom Type Name", income_event.custom_label
  end

  test "display_name returns income name if income is present" do
    income_event = income_events(:one) # Has income_id and custom_label
    assert_equal income_event.income.name, income_event.display_name
  end

  test "display_name returns custom_label if income is nil" do
    income_event = IncomeEvent.new(
      user: @user_one,
      income: nil,
      custom_label: "Birthday Gift",
      month_year: "2025-12",
      received_on: Date.today,
      actual_amount: 50.00
    )
    assert_equal "Birthday Gift", income_event.display_name
  end

  test "display_name returns nil if both income and custom_label are nil" do
    income_event = IncomeEvent.new(
      user: @user_one,
      income: nil,
      custom_label: nil,
      month_year: "2025-12",
      received_on: Date.today,
      actual_amount: 50.00
    )
    # This scenario should be prevented by validation, but testing the method's behavior
    assert_nil income_event.display_name
  end
end

require "test_helper"

class IncomeTest < ActiveSupport::TestCase
  # Test fixtures
  test "should have valid fixtures" do
    assert incomes(:one).valid?
    assert incomes(:two).valid?
    assert incomes(:three).valid?
  end

  # Test associations
  test "should belong to user" do
    income = incomes(:one)
    assert_not_nil income.user
    assert_equal users(:one), income.user
  end

  test "should be destroyed when user is destroyed" do
    user = users(:one)
    income = user.incomes.create!(name: "Test Income", frequency: "monthly", estimated_amount: 100)
    income_id = income.id
    
    user.destroy
    assert_nil Income.find_by(id: income_id)
  end

  # Test name validation
  test "name should be present" do
    income = Income.new(user: users(:one), frequency: "monthly", estimated_amount: 100)
    assert_not income.valid?
    assert_includes income.errors[:name], "can't be blank"
  end

  test "should save with valid name" do
    income = Income.new(user: users(:one), name: "New Income", frequency: "monthly", estimated_amount: 100)
    assert income.save
    assert_equal "New Income", income.name
  end

  # Test estimated_amount validation
  test "estimated_amount should be numeric" do
    income = Income.new(user: users(:one), name: "Test", frequency: "monthly", estimated_amount: "not_a_number")
    assert_not income.valid?
    assert_includes income.errors[:estimated_amount], "is not a number"
  end

  test "estimated_amount should be greater than or equal to 0" do
    income = Income.new(user: users(:one), name: "Test", frequency: "monthly", estimated_amount: -100)
    assert_not income.valid?
    assert_includes income.errors[:estimated_amount], "must be greater than or equal to 0"
  end

  test "estimated_amount can be zero" do
    income = Income.new(user: users(:one), name: "Test", frequency: "monthly", estimated_amount: 0)
    assert income.valid?
  end

  test "estimated_amount can be decimal" do
    income = Income.new(user: users(:one), name: "Test", frequency: "monthly", estimated_amount: 1234.56)
    assert income.save
    assert_equal 1234.56, income.estimated_amount
  end

  # Test frequency validation
  test "frequency should be included in FREQUENCIES" do
    income = Income.new(user: users(:one), name: "Test", frequency: "invalid", estimated_amount: 100)
    assert_not income.valid?
    assert_includes income.errors[:frequency], "is not included in the list"
  end

  test "should accept valid frequencies" do
    Income::FREQUENCIES.each do |frequency|
      income = Income.new(user: users(:one), name: "Test #{frequency}", frequency: frequency, estimated_amount: 100)
      assert income.valid?, "Frequency #{frequency} should be valid"
    end
  end

  test "frequency should default to monthly" do
    income = Income.new(user: users(:one), name: "Test", estimated_amount: 100)
    assert_equal "monthly", income.frequency
  end

  # Test uniqueness constraint
  test "should enforce unique name per user" do
    user = users(:one)
    Income.create!(user: user, name: "Unique Income Source", frequency: "monthly", estimated_amount: 100)
    
    duplicate = Income.new(user: user, name: "Unique Income Source", frequency: "monthly", estimated_amount: 200)
    assert_not duplicate.valid?
    assert_includes duplicate.errors[:name], "has already been taken"
  end

  test "different users can have incomes with same name" do
    user1 = users(:one)
    user2 = users(:two)
    
    # Use a unique name that doesn't conflict with fixtures
    income1 = Income.create!(user: user1, name: "Shared Income Name", frequency: "monthly", estimated_amount: 100)
    income2 = Income.new(user: user2, name: "Shared Income Name", frequency: "monthly", estimated_amount: 200)
    
    assert income2.valid?
    assert income2.save
    assert_equal "Shared Income Name", income1.name
    assert_equal "Shared Income Name", income2.name
  end

  # Test active scope
  test "active scope should return only active incomes" do
    user = users(:two)
    active_count = user.incomes.active.count
    total_count = user.incomes.count
    
    assert active_count < total_count, "Should have both active and inactive incomes"
    assert user.incomes.active.all?(&:active?), "All scoped incomes should be active"
  end

  test "active scope should exclude inactive incomes" do
    user = users(:two)
    inactive_income = incomes(:four)
    
    assert_not user.incomes.active.include?(inactive_income)
  end

  # Test active attribute
  test "active should default to true" do
    income = Income.new(user: users(:one), name: "Test", frequency: "monthly", estimated_amount: 100)
    assert_equal true, income.active
  end

  test "can set active to false" do
    income = Income.create!(user: users(:one), name: "Inactive Income", frequency: "monthly", estimated_amount: 100, active: false)
    assert_equal false, income.active
  end

  # Test edge cases
  test "should handle very large amounts" do
    income = Income.new(user: users(:one), name: "Large Income", frequency: "monthly", estimated_amount: 999999999.99)
    assert income.valid?
  end

  test "name can contain special characters" do
    income = Income.new(user: users(:one), name: "Income $1000+", frequency: "monthly", estimated_amount: 1000)
    assert income.valid?
  end
end


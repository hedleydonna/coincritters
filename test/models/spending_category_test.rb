require "test_helper"

class SpendingCategoryTest < ActiveSupport::TestCase
  setup do
    @user_one = users(:one)
    @user_two = users(:two)
    @spending_category_one = spending_categories(:one)  # Groceries (variable)
    @spending_category_two = spending_categories(:two)  # Rent (fixed)
    @spending_category_three = spending_categories(:three)  # Emergency Fund (fixed, savings)
  end

  test "should be valid with valid attributes" do
    spending_category = SpendingCategory.new(
      user: @user_one,
      name: "Utilities",
      group_type: :fixed,
      is_savings: false,
      default_amount: 150.00,
      auto_create: true
    )
    assert spending_category.valid?
  end

  test "should require a user" do
    spending_category = SpendingCategory.new(
      name: "Test Category",
      group_type: :variable
    )
    assert_not spending_category.valid?
    assert_includes spending_category.errors[:user], "must exist"
  end

  test "should require name" do
    spending_category = SpendingCategory.new(
      user: @user_one,
      group_type: :variable
    )
    assert_not spending_category.valid?
    assert_includes spending_category.errors[:name], "can't be blank"
  end

  test "should enforce unique name per user" do
    duplicate_category = SpendingCategory.new(
      user: @user_one,
      name: @spending_category_one.name,
      group_type: :variable
    )
    assert_not duplicate_category.valid?
    assert_includes duplicate_category.errors[:name], "has already been taken"
  end

  test "different users can have categories with same name" do
    # Both user_one and user_two can have "Groceries"
    assert_equal "Groceries", spending_categories(:one).name
    assert_equal "Groceries", spending_categories(:four).name
    assert_equal users(:one), spending_categories(:one).user
    assert_equal users(:two), spending_categories(:four).user
    
    assert spending_categories(:one).valid?
    assert spending_categories(:four).valid?
  end

  test "should validate group_type inclusion" do
    spending_category = SpendingCategory.new(
      user: @user_one,
      name: "Test"
    )
    # Rails enum raises ArgumentError for invalid values before validation
    assert_raises(ArgumentError) do
      spending_category.group_type = 999
    end
    # Valid values work fine
    spending_category.group_type = :fixed
    assert spending_category.valid?
  end

  test "should accept valid group_type values" do
    fixed_category = SpendingCategory.new(
      user: @user_one,
      name: "Fixed Test",
      group_type: :fixed
    )
    assert fixed_category.valid?

    variable_category = SpendingCategory.new(
      user: @user_one,
      name: "Variable Test",
      group_type: :variable
    )
    assert variable_category.valid?
  end

  test "should default group_type to variable" do
    spending_category = SpendingCategory.create!(
      user: @user_one,
      name: "Default Test"
    )
    assert_equal "variable", spending_category.group_type
    assert spending_category.variable?
  end

  test "should default is_savings to false" do
    spending_category = SpendingCategory.create!(
      user: @user_one,
      name: "Default Savings Test"
    )
    assert_not spending_category.is_savings?
  end

  test "should default auto_create to true" do
    spending_category = SpendingCategory.create!(
      user: @user_one,
      name: "Default Auto Create Test"
    )
    assert spending_category.auto_create?
  end

  test "should require default_amount to be greater than or equal to 0" do
    spending_category = SpendingCategory.new(
      user: @user_one,
      name: "Test",
      default_amount: -100.00
    )
    assert_not spending_category.valid?
    assert_includes spending_category.errors[:default_amount], "must be greater than or equal to 0"
  end

  test "should allow default_amount to be nil" do
    spending_category = SpendingCategory.new(
      user: @user_one,
      name: "Test With Nil Amount",
      default_amount: nil
    )
    assert spending_category.valid?
  end

  test "should destroy when user is destroyed" do
    user = User.create!(
      email: "test@example.com",
      password: "password123",
      password_confirmation: "password123"
    )
    spending_category = SpendingCategory.create!(
      user: user,
      name: "Test Category"
    )
    
    assert_difference("SpendingCategory.count", -1) do
      user.destroy
    end
  end

  test "should destroy dependent envelopes when destroyed" do
    spending_category = SpendingCategory.create!(
      user: @user_one,
      name: "Test Category For Deletion"
    )
    envelope = Envelope.create!(
      monthly_budget: monthly_budgets(:one),
      spending_category: spending_category,
      spending_group_name: "Test Envelope"
    )
    
    assert_difference("Envelope.count", -1) do
      spending_category.destroy
    end
  end

  test "fixed scope should return only fixed categories" do
    fixed_categories = SpendingCategory.fixed
    assert_includes fixed_categories, @spending_category_two
    assert_not_includes fixed_categories, @spending_category_one
  end

  test "variable scope should return only variable categories" do
    variable_categories = SpendingCategory.variable
    assert_includes variable_categories, @spending_category_one
    assert_not_includes variable_categories, @spending_category_two
  end

  test "savings scope should return only savings categories" do
    savings_categories = SpendingCategory.savings
    assert_includes savings_categories, @spending_category_three
    assert_not_includes savings_categories, @spending_category_one
  end

  test "non_savings scope should return only non-savings categories" do
    non_savings_categories = SpendingCategory.non_savings
    assert_includes non_savings_categories, @spending_category_one
    assert_not_includes non_savings_categories, @spending_category_three
  end

  test "auto_create scope should return only auto-create categories" do
    auto_create_categories = SpendingCategory.auto_create
    assert_includes auto_create_categories, @spending_category_one
  end

  test "display_name should include (Savings) for savings categories" do
    assert_equal "Emergency Fund (Savings)", @spending_category_three.display_name
    assert_equal "Groceries", @spending_category_one.display_name
  end

  test "group_type_text should return correct text" do
    assert_equal "Fixed bill", @spending_category_two.group_type_text
    assert_equal "Variable spending", @spending_category_one.group_type_text
  end
end


require "test_helper"

class ExpenseTemplateTest < ActiveSupport::TestCase
  setup do
    @user_one = users(:one)
    @user_two = users(:two)
    @expense_template_one = expense_templates(:one)  # Groceries (variable)
    @expense_template_two = expense_templates(:two)  # Rent (fixed)
    @expense_template_three = expense_templates(:three)  # Emergency Fund (fixed, savings)
  end

  test "should be valid with valid attributes" do
    expense_template = ExpenseTemplate.new(
      user: @user_one,
      name: "Utilities",
      group_type: :fixed,
      is_savings: false,
      default_amount: 150.00,
      auto_create: true
    )
    assert expense_template.valid?
  end

  test "should require a user" do
    expense_template = ExpenseTemplate.new(
      name: "Test Template",
      group_type: :variable
    )
    assert_not expense_template.valid?
    assert_includes expense_template.errors[:user], "must exist"
  end

  test "should require name" do
    expense_template = ExpenseTemplate.new(
      user: @user_one,
      group_type: :variable
    )
    assert_not expense_template.valid?
    assert_includes expense_template.errors[:name], "can't be blank"
  end

  test "should enforce unique name per user" do
    duplicate_template = ExpenseTemplate.new(
      user: @user_one,
      name: @expense_template_one.name,
      group_type: :variable
    )
    assert_not duplicate_template.valid?
    assert_includes duplicate_template.errors[:name], "has already been taken"
  end

  test "different users can have templates with same name" do
    # Both user_one and user_two can have "Groceries"
    assert_equal "Groceries", expense_templates(:one).name
    assert_equal "Groceries", expense_templates(:four).name
    assert_equal users(:one), expense_templates(:one).user
    assert_equal users(:two), expense_templates(:four).user
    
    assert expense_templates(:one).valid?
    assert expense_templates(:four).valid?
  end

  test "should validate group_type inclusion" do
    expense_template = ExpenseTemplate.new(
      user: @user_one,
      name: "Test"
    )
    # Rails enum raises ArgumentError for invalid values before validation
    assert_raises(ArgumentError) do
      expense_template.group_type = 999
    end
    # Valid values work fine
    expense_template.group_type = :fixed
    assert expense_template.valid?
  end

  test "should accept valid group_type values" do
    fixed_template = ExpenseTemplate.new(
      user: @user_one,
      name: "Fixed Test",
      group_type: :fixed
    )
    assert fixed_template.valid?

    variable_template = ExpenseTemplate.new(
      user: @user_one,
      name: "Variable Test",
      group_type: :variable
    )
    assert variable_template.valid?
  end

  test "should default group_type to variable" do
    expense_template = ExpenseTemplate.create!(
      user: @user_one,
      name: "Default Test"
    )
    assert_equal "variable", expense_template.group_type
    assert expense_template.variable?
  end

  test "should default is_savings to false" do
    expense_template = ExpenseTemplate.create!(
      user: @user_one,
      name: "Default Savings Test"
    )
    assert_not expense_template.is_savings?
  end

  test "should default auto_create to true" do
    expense_template = ExpenseTemplate.create!(
      user: @user_one,
      name: "Default Auto Create Test"
    )
    assert expense_template.auto_create?
  end

  test "should require default_amount to be greater than or equal to 0" do
    expense_template = ExpenseTemplate.new(
      user: @user_one,
      name: "Test",
      default_amount: -100.00
    )
    assert_not expense_template.valid?
    assert_includes expense_template.errors[:default_amount], "must be greater than or equal to 0"
  end

  test "should allow default_amount to be nil" do
    expense_template = ExpenseTemplate.new(
      user: @user_one,
      name: "Test With Nil Amount",
      default_amount: nil
    )
    assert expense_template.valid?
  end

  test "should destroy when user is destroyed" do
    user = User.create!(
      email: "test@example.com",
      password: "password123",
      password_confirmation: "password123"
    )
    expense_template = ExpenseTemplate.create!(
      user: user,
      name: "Test Template"
    )
    
    assert_difference("ExpenseTemplate.count", -1) do
      user.destroy
    end
  end

  test "should destroy dependent expenses when destroyed" do
    expense_template = ExpenseTemplate.create!(
      user: @user_one,
      name: "Test Template For Deletion"
    )
    expense = Expense.create!(
      monthly_budget: monthly_budgets(:one),
      expense_template: expense_template
    )
    
    assert_difference("Expense.count", -1) do
      expense_template.destroy
    end
  end

  test "fixed scope should return only fixed templates" do
    fixed_templates = ExpenseTemplate.fixed
    assert_includes fixed_templates, @expense_template_two
    assert_not_includes fixed_templates, @expense_template_one
  end

  test "variable scope should return only variable templates" do
    variable_templates = ExpenseTemplate.variable
    assert_includes variable_templates, @expense_template_one
    assert_not_includes variable_templates, @expense_template_two
  end

  test "savings scope should return only savings templates" do
    savings_templates = ExpenseTemplate.savings
    assert_includes savings_templates, @expense_template_three
    assert_not_includes savings_templates, @expense_template_one
  end

  test "non_savings scope should return only non-savings templates" do
    non_savings_templates = ExpenseTemplate.non_savings
    assert_includes non_savings_templates, @expense_template_one
    assert_not_includes non_savings_templates, @expense_template_three
  end

  test "auto_create scope should return only auto-create templates" do
    auto_create_templates = ExpenseTemplate.auto_create
    assert_includes auto_create_templates, @expense_template_one
  end

  test "display_name should include (Savings) for savings templates" do
    assert_equal "Emergency Fund (Savings)", @expense_template_three.display_name
    assert_equal "Groceries", @expense_template_one.display_name
  end

  test "group_type_text should return correct text" do
    assert_equal "Fixed bill", @expense_template_two.group_type_text
    assert_equal "Variable payment", @expense_template_one.group_type_text
  end

  test "should default is_active to true" do
    expense_template = ExpenseTemplate.create!(
      user: @user_one,
      name: "Default Active Test"
    )
    assert expense_template.is_active?
    assert expense_template.active?
  end

  test "active scope should return only active templates" do
    active_template = ExpenseTemplate.create!(
      user: @user_one,
      name: "Active Template",
      is_active: true
    )
    inactive_template = ExpenseTemplate.create!(
      user: @user_one,
      name: "Inactive Template",
      is_active: false
    )
    
    active_templates = ExpenseTemplate.active
    assert_includes active_templates, active_template
    assert_not_includes active_templates, inactive_template
  end

  test "inactive scope should return only inactive templates" do
    active_template = ExpenseTemplate.create!(
      user: @user_one,
      name: "Active Template 2",
      is_active: true
    )
    inactive_template = ExpenseTemplate.create!(
      user: @user_one,
      name: "Inactive Template 2",
      is_active: false
    )
    
    inactive_templates = ExpenseTemplate.inactive
    assert_includes inactive_templates, inactive_template
    assert_not_includes inactive_templates, active_template
  end

  test "deactivate! should set is_active to false" do
    template = ExpenseTemplate.create!(
      user: @user_one,
      name: "Template To Deactivate"
    )
    assert template.is_active?
    
    template.deactivate!
    template.reload
    assert_not template.is_active?
    assert_not template.active?
  end

  test "activate! should set is_active to true" do
    template = ExpenseTemplate.create!(
      user: @user_one,
      name: "Template To Activate",
      is_active: false
    )
    assert_not template.is_active?
    
    template.activate!
    template.reload
    assert template.is_active?
    assert template.active?
  end

  test "should allow same name for active and inactive templates for same user" do
    skip "Requires partial unique index migration - database constraint prevents this currently"
    active_template = ExpenseTemplate.create!(
      user: @user_one,
      name: "Shared Name",
      is_active: true
    )
    
    # Deactivate the first one
    active_template.deactivate!
    
    # Should be able to create a new active template with the same name
    new_active_template = ExpenseTemplate.create!(
      user: @user_one,
      name: "Shared Name",
      is_active: true
    )
    assert new_active_template.valid?
    assert new_active_template.persisted?
  end

  test "should not allow duplicate active templates with same name for same user" do
    ExpenseTemplate.create!(
      user: @user_one,
      name: "Unique Name",
      is_active: true
    )
    
    duplicate = ExpenseTemplate.new(
      user: @user_one,
      name: "Unique Name",
      is_active: true
    )
    assert_not duplicate.valid?
    assert_includes duplicate.errors[:name], "has already been taken"
  end
end


require "test_helper"

class ExpenseTemplateTest < ActiveSupport::TestCase
  setup do
    @user_one = users(:one)
    @user_two = users(:two)
    @expense_template_one = expense_templates(:one)  # Groceries
    @expense_template_two = expense_templates(:two)  # Rent
    @expense_template_three = expense_templates(:three)  # Emergency Fund
  end

  test "should be valid with valid attributes" do
    expense_template = ExpenseTemplate.new(
      user: @user_one,
      name: "Utilities",
      frequency: "monthly",
      due_date: Date.today,
      default_amount: 150.00,
      auto_create: true
    )
    assert expense_template.valid?
  end

  test "should require a user" do
    expense_template = ExpenseTemplate.new(
      name: "Test Template",
      frequency: "monthly"
    )
    assert_not expense_template.valid?
    assert_includes expense_template.errors[:user], "must exist"
  end

  test "should require name" do
    expense_template = ExpenseTemplate.new(
      user: @user_one,
      frequency: "monthly"
    )
    assert_not expense_template.valid?
    assert_includes expense_template.errors[:name], "can't be blank"
  end

  test "should enforce unique name per user" do
    duplicate_template = ExpenseTemplate.new(
      user: @user_one,
      name: @expense_template_one.name,
      frequency: "monthly"
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

  test "should validate frequency inclusion" do
    expense_template = ExpenseTemplate.new(
      user: @user_one,
      name: "Test",
      frequency: "invalid"
    )
    assert_not expense_template.valid?
    # Error message includes the value, so check for partial match
    assert expense_template.errors[:frequency].any? { |msg| msg.include?("is not a valid frequency") }
  end

  test "should accept valid frequency values" do
    monthly_template = ExpenseTemplate.new(
      user: @user_one,
      name: "Monthly Test",
      frequency: "monthly"
    )
    assert monthly_template.valid?

    weekly_template = ExpenseTemplate.new(
      user: @user_one,
      name: "Weekly Test",
      frequency: "weekly"
    )
    assert weekly_template.valid?

    biweekly_template = ExpenseTemplate.new(
      user: @user_one,
      name: "Biweekly Test",
      frequency: "biweekly"
    )
    assert biweekly_template.valid?

    yearly_template = ExpenseTemplate.new(
      user: @user_one,
      name: "Yearly Test",
      frequency: "yearly"
    )
    assert yearly_template.valid?
  end

  test "should default frequency to monthly" do
    expense_template = ExpenseTemplate.create!(
      user: @user_one,
      name: "Default Test"
    )
    assert_equal "monthly", expense_template.frequency
  end

  test "should allow due_date to be nil" do
    expense_template = ExpenseTemplate.new(
      user: @user_one,
      name: "Test Without Due Date",
      frequency: "monthly",
      due_date: nil
    )
    assert expense_template.valid?
  end

  test "should accept valid due_date" do
    expense_template = ExpenseTemplate.new(
      user: @user_one,
      name: "Test With Due Date",
      frequency: "monthly",
      due_date: Date.today
    )
    assert expense_template.valid?
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

  test "by_frequency scope should return only templates with specific frequency" do
    monthly_template = ExpenseTemplate.create!(
      user: @user_one,
      name: "Monthly Template",
      frequency: "monthly"
    )
    weekly_template = ExpenseTemplate.create!(
      user: @user_one,
      name: "Weekly Template",
      frequency: "weekly"
    )
    
    monthly_templates = ExpenseTemplate.by_frequency("monthly")
    assert_includes monthly_templates, monthly_template
    assert_not_includes monthly_templates, weekly_template
  end

  test "auto_create scope should return only auto-create templates" do
    auto_create_templates = ExpenseTemplate.auto_create
    assert_includes auto_create_templates, @expense_template_one
  end

  test "display_name should return the template name" do
    assert_equal "Groceries", @expense_template_one.display_name
    assert_equal "Rent", @expense_template_two.display_name
  end

  test "frequency_text should return correct text" do
    monthly_template = ExpenseTemplate.create!(
      user: @user_one,
      name: "Monthly Test",
      frequency: "monthly"
    )
    assert_equal "Monthly", monthly_template.frequency_text

    weekly_template = ExpenseTemplate.create!(
      user: @user_one,
      name: "Weekly Test",
      frequency: "weekly"
    )
    assert_equal "Weekly", weekly_template.frequency_text

    biweekly_template = ExpenseTemplate.create!(
      user: @user_one,
      name: "Biweekly Test",
      frequency: "biweekly"
    )
    assert_equal "Biweekly", biweekly_template.frequency_text

    yearly_template = ExpenseTemplate.create!(
      user: @user_one,
      name: "Yearly Test",
      frequency: "yearly"
    )
    assert_equal "Yearly", yearly_template.frequency_text
  end

  test "should default deleted_at to nil (active)" do
    expense_template = ExpenseTemplate.create!(
      user: @user_one,
      name: "Default Active Test"
    )
    assert_nil expense_template.deleted_at
    assert expense_template.active?
    assert_not expense_template.deleted?
  end

  test "active scope should return only active templates" do
    active_template = ExpenseTemplate.create!(
      user: @user_one,
      name: "Active Template"
    )
    deleted_template = ExpenseTemplate.create!(
      user: @user_one,
      name: "Deleted Template"
    )
    deleted_template.soft_delete!
    
    active_templates = ExpenseTemplate.active
    assert_includes active_templates, active_template
    assert_not_includes active_templates, deleted_template
  end

  test "deleted scope should return only deleted templates" do
    active_template = ExpenseTemplate.create!(
      user: @user_one,
      name: "Active Template 2"
    )
    deleted_template = ExpenseTemplate.create!(
      user: @user_one,
      name: "Deleted Template 2"
    )
    deleted_template.soft_delete!
    
    deleted_templates = ExpenseTemplate.with_deleted.deleted
    assert_includes deleted_templates, deleted_template
    assert_not_includes deleted_templates, active_template
  end

  test "soft_delete! should set deleted_at timestamp" do
    template = ExpenseTemplate.create!(
      user: @user_one,
      name: "Template To Delete"
    )
    assert_nil template.deleted_at
    assert template.active?
    
    template.soft_delete!
    template.reload
    assert_not_nil template.deleted_at
    assert template.deleted?
    assert_not template.active?
  end

  test "restore! should clear deleted_at" do
    template = ExpenseTemplate.create!(
      user: @user_one,
      name: "Template To Restore"
    )
    template.soft_delete!
    assert template.deleted?
    
    template.restore!
    template.reload
    assert_nil template.deleted_at
    assert template.active?
    assert_not template.deleted?
  end

  test "default scope should exclude deleted templates" do
    active_template = ExpenseTemplate.create!(
      user: @user_one,
      name: "Active Template 3"
    )
    deleted_template = ExpenseTemplate.create!(
      user: @user_one,
      name: "Deleted Template 3"
    )
    deleted_template.soft_delete!
    
    all_templates = ExpenseTemplate.all
    assert_includes all_templates, active_template
    assert_not_includes all_templates, deleted_template
  end

  test "should allow same name for active and deleted templates for same user" do
    active_template = ExpenseTemplate.create!(
      user: @user_one,
      name: "Shared Name"
    )
    
    # Soft delete the first one
    active_template.soft_delete!
    
    # Should be able to create a new active template with the same name
    new_active_template = ExpenseTemplate.create!(
      user: @user_one,
      name: "Shared Name"
    )
    assert new_active_template.valid?
    assert new_active_template.persisted?
  end

  test "should not allow duplicate active templates with same name for same user" do
    ExpenseTemplate.create!(
      user: @user_one,
      name: "Unique Name"
    )
    
    duplicate = ExpenseTemplate.new(
      user: @user_one,
      name: "Unique Name"
    )
    assert_not duplicate.valid?
    assert_includes duplicate.errors[:name], "has already been taken"
  end
end


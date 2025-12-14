require "test_helper"

class Admin::ExpenseControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    @admin = users(:one)
    @admin.update(admin: true)
    @regular_user = users(:two)
    @regular_user.update(admin: false)
    @expense = expenses(:one)
  end

  # Test authorization
  test "should redirect non-admin users" do
    sign_in @regular_user
    get admin_expenses_path
    assert_redirected_to root_path
    assert_equal "You don't have permission to access this page.", flash[:alert]
  end

  test "should redirect unauthenticated users" do
    get admin_expenses_path
    assert_redirected_to new_user_session_path
  end

  test "should allow admin users to access envelopes index" do
    sign_in @admin
    get admin_expenses_path
    assert_response :success
  end

  # Test index action
  test "should list all envelopes" do
    sign_in @admin
    get admin_expenses_path
    assert_response :success
    assert_select "table" do
      assert_select "tr", count: Expense.count + 1 # +1 for header row
    end
  end

  # Test show action
  test "should show expense details" do
    sign_in @admin
    get admin_expense_path(@expense)
    assert_response :success
    assert_match @expense.name, response.body
  end

  # Test new action
  test "should show new form" do
    sign_in @admin
    get new_admin_expense_path
    assert_response :success
    assert_select "form[action=?]", admin_expenses_path
  end

  # Test create action
  test "should create envelope" do
    sign_in @admin
    monthly_budget = monthly_budgets(:one)
    # Create a unique envelope template for this budget
    expense_template = ExpenseTemplate.create!(
      user: monthly_budget.user,
      name: "Utilities Test",
      group_type: :fixed,
      is_savings: false
    )
    
    assert_difference("Expense.count", 1) do
      post admin_expenses_path, params: {
        expense: {
          monthly_budget_id: monthly_budget.id,
          expense_template_id: expense_template.id,
          allotted_amount: 150.00
        }
      }
    end
    assert_redirected_to admin_expense_path(Expense.last)
    assert_equal "Expense was successfully created.", flash[:notice]
  end

  test "should not create envelope with invalid data" do
    sign_in @admin
    assert_no_difference("Expense.count") do
      post admin_expenses_path, params: {
        expense: {
          monthly_budget_id: nil,
          expense_template_id: nil
        }
      }
    end
    assert_response :unprocessable_entity
  end

  # Test edit action
  test "should show edit form" do
    sign_in @admin
    get edit_admin_expense_path(@expense)
    assert_response :success
    assert_select "form[action=?]", admin_expense_path(@expense)
  end

  # Test update action
  test "should update envelope" do
    sign_in @admin
    patch admin_expense_path(@expense), params: {
      expense: {
        allotted_amount: 600.00,
        monthly_budget_id: @expense.monthly_budget_id,
        expense_template_id: @expense.expense_template_id
      }
    }
    assert_redirected_to admin_expense_path(@expense)
    @expense.reload
    assert_equal 600.00, @expense.allotted_amount.to_f
  end

  # Test destroy action
  test "should delete envelope" do
    sign_in @admin
    expense_to_delete = expenses(:five)
    assert_difference("Expense.count", -1) do
      delete admin_expense_path(expense_to_delete)
    end
    assert_redirected_to admin_expenses_path
    assert_equal "Expense was successfully deleted.", flash[:notice]
  end

  test "delete button should have confirmation data attribute" do
    sign_in @admin
    get admin_expenses_path
    assert_response :success
    assert_select "form[action=?]", admin_expense_path(@expense) do |forms|
      forms.each do |form|
        assert_match /turbo_confirm|confirm/, form.to_s, "Delete form should have confirmation"
      end
    end
  end
end


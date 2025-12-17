require "test_helper"

class ExpenseTemplatesControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    @user = users(:one)
    @expense_template = expense_templates(:one)
  end

  test "should require authentication" do
    # Routes are inside authenticated block, so unauthenticated users get 404
    get expense_templates_path
    assert_response :not_found
  end

  test "should get index" do
    sign_in @user
    get expense_templates_path
    assert_response :success
  end

  test "should get index with return_to parameter" do
    sign_in @user
    get expense_templates_path(return_to: 'expenses')
    assert_response :success
    assert_match /Back to Spending/, response.body
  end

  test "should get index without return_to shows dashboard link" do
    sign_in @user
    get expense_templates_path
    assert_response :success
    assert_match /Return to Dashboard/, response.body
  end

  test "should get new" do
    sign_in @user
    get new_expense_template_path
    assert_response :success
  end

  test "should get new with return_to parameter" do
    sign_in @user
    get new_expense_template_path(return_to: 'expenses')
    assert_response :success
  end

  test "should create expense template and redirect based on return_to" do
    sign_in @user
    assert_difference("ExpenseTemplate.count", 1) do
      post expense_templates_path, params: {
        expense_template: {
          name: "Test Template",
          frequency: "monthly",
          default_amount: 100.00,
          auto_create: true
        },
        return_to: 'expenses'
      }
    end
    assert_redirected_to expenses_path
  end

  test "should create expense template and redirect to templates index when no return_to" do
    sign_in @user
    assert_difference("ExpenseTemplate.count", 1) do
      post expense_templates_path, params: {
        expense_template: {
          name: "Test Template",
          frequency: "monthly",
          default_amount: 100.00,
          auto_create: true
        }
      }
    end
    assert_redirected_to expense_templates_path
  end

  test "should get edit" do
    sign_in @user
    get edit_expense_template_path(@expense_template)
    assert_response :success
  end

  test "should get edit with return_to parameter" do
    sign_in @user
    get edit_expense_template_path(@expense_template, return_to: 'expenses')
    assert_response :success
  end

  test "should update expense template and redirect based on return_to" do
    sign_in @user
    patch expense_template_path(@expense_template), params: {
      expense_template: {
        name: "Updated Template",
        default_amount: 200.00
      },
      return_to: 'expenses'
    }
    assert_redirected_to expenses_path
    @expense_template.reload
    assert_equal "Updated Template", @expense_template.name
  end

  test "should update expense template and redirect to templates index when no return_to" do
    sign_in @user
    patch expense_template_path(@expense_template), params: {
      expense_template: {
        name: "Updated Template",
        default_amount: 200.00
      }
    }
    assert_redirected_to expense_templates_path
  end

  test "should destroy expense template and redirect based on return_to" do
    sign_in @user
    template = ExpenseTemplate.create!(
      user: @user,
      name: "To Delete",
      frequency: "monthly",
      auto_create: true
    )
    delete expense_template_path(template, return_to: 'expenses')
    assert_redirected_to expenses_path
    template.reload
    assert_not template.is_active?
  end

  test "should reactivate expense template and redirect based on return_to" do
    sign_in @user
    template = ExpenseTemplate.create!(
      user: @user,
      name: "To Reactivate",
      frequency: "monthly",
      auto_create: true,
      is_active: false
    )
    patch reactivate_expense_template_path(template, return_to: 'expenses')
    assert_redirected_to expenses_path
    template.reload
    assert template.is_active?
  end
end


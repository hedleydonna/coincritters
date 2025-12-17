require "test_helper"

class IncomeTemplatesControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    @user = users(:one)
    @income_template = income_templates(:one)
  end

  test "should require authentication" do
    # Routes are inside authenticated block, so unauthenticated users get 404
    get income_templates_path
    assert_response :not_found
  end

  test "should get index" do
    sign_in @user
    get income_templates_path
    assert_response :success
  end

  test "should get index with return_to parameter" do
    sign_in @user
    get income_templates_path(return_to: 'income_events')
    assert_response :success
    assert_match /Back to Money In/, response.body
  end

  test "should get index without return_to shows dashboard link" do
    sign_in @user
    get income_templates_path
    assert_response :success
    assert_match /Return to Dashboard/, response.body
  end

  test "should get new" do
    sign_in @user
    get new_income_template_path
    assert_response :success
  end

  test "should get new with return_to parameter" do
    sign_in @user
    get new_income_template_path(return_to: 'income_events')
    assert_response :success
  end

  test "should create income template and redirect based on return_to" do
    sign_in @user
    assert_difference("IncomeTemplate.count", 1) do
      post income_templates_path, params: {
        income_template: {
          name: "Test Income Source",
          frequency: "monthly",
          estimated_amount: 1000.00,
          auto_create: true,
          active: true,
          due_date: Date.today
        },
        return_to: 'income_events'
      }
    end
    assert_redirected_to income_events_path
  end

  test "should create income template and redirect to templates index when no return_to" do
    sign_in @user
    assert_difference("IncomeTemplate.count", 1) do
      post income_templates_path, params: {
        income_template: {
          name: "Test Income Source",
          frequency: "monthly",
          estimated_amount: 1000.00,
          auto_create: true,
          active: true,
          due_date: Date.today
        }
      }
    end
    assert_redirected_to income_templates_path
  end

  test "should get edit" do
    sign_in @user
    get edit_income_template_path(@income_template)
    assert_response :success
  end

  test "should get edit with return_to parameter" do
    sign_in @user
    get edit_income_template_path(@income_template, return_to: 'income_events')
    assert_response :success
  end

  test "should update income template and redirect based on return_to" do
    sign_in @user
    patch income_template_path(@income_template), params: {
      income_template: {
        name: "Updated Income Source",
        estimated_amount: 2000.00
      },
      return_to: 'income_events'
    }
    assert_redirected_to income_events_path
    @income_template.reload
    assert_equal "Updated Income Source", @income_template.name
  end

  test "should update income template and redirect to templates index when no return_to" do
    sign_in @user
    patch income_template_path(@income_template), params: {
      income_template: {
        name: "Updated Income Source",
        estimated_amount: 2000.00
      }
    }
    assert_redirected_to income_templates_path
  end

  test "should destroy income template and redirect based on return_to" do
    sign_in @user
    template = IncomeTemplate.create!(
      user: @user,
      name: "To Delete",
      frequency: "monthly",
      estimated_amount: 500.00,
      active: true
    )
    delete income_template_path(template, return_to: 'income_events')
    assert_redirected_to income_events_path
    template.reload
    assert_not template.active?
  end

  test "should reactivate income template and redirect based on return_to" do
    sign_in @user
    template = IncomeTemplate.create!(
      user: @user,
      name: "To Reactivate",
      frequency: "monthly",
      estimated_amount: 500.00,
      active: false
    )
    patch reactivate_income_template_path(template, return_to: 'income_events')
    assert_redirected_to income_events_path
    template.reload
    assert template.active?
  end
end


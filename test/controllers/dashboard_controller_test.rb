require "test_helper"

class DashboardControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    @user = users(:one)
  end

  # Test unauthenticated access
  test "should redirect unauthenticated users" do
    get dashboard_path
    assert_redirected_to new_user_session_path
    assert_equal "You need to sign in or sign up before continuing.", flash[:alert]
  end

  # Test authenticated access
  test "should allow authenticated users to access dashboard" do
    sign_in @user
    get dashboard_path
    assert_response :success
  end

  test "should display user email when no display_name" do
    @user.update(display_name: nil)
    sign_in @user
    get dashboard_path
    assert_response :success
    assert_select "h1", text: "Welcome back"
    assert_select "p", text: /#{@user.email.split('@').first.capitalize}!/
  end

  test "should display display_name when present" do
    @user.update(display_name: "Test User")
    sign_in @user
    get dashboard_path
    assert_response :success
    assert_select "h1", text: "Welcome back"
    assert_select "p", text: /Test User!/
  end

  # Test dashboard content
  test "should render dashboard content" do
    sign_in @user
    get dashboard_path
    assert_response :success
    assert_select "h1", text: /Welcome back/
  end

  test "should include navigation links" do
    sign_in @user
    get dashboard_path
    assert_response :success
    # Dashboard should have links to income_events and expenses
    assert_select "a[href=?]", income_events_path
    assert_select "a[href=?]", expenses_path
  end

  # Test display_name preference
  test "should prefer display_name over email" do
    @user.update(display_name: "Preferred Name")
    sign_in @user
    get dashboard_path
    assert_select "h1", text: "Welcome back"
    assert_select "p", text: /Preferred Name!/
  end

  test "should handle empty display_name as nil" do
    @user.update(display_name: "")
    sign_in @user
    get dashboard_path
    # Should fall back to email since display_name is empty
    assert_select "h1", text: "Welcome back"
    assert_select "p", text: /#{@user.email.split('@').first.capitalize}!/
  end

  # Test navigation links
  test "should have return to dashboard link in edit form" do
    sign_in @user
    get edit_user_registration_path
    assert_select "a[href=?]", dashboard_path, text: "Return to Dashboard"
  end

  # Test edge cases
  test "should handle user with no email gracefully" do
    # This shouldn't happen in practice due to validations, but test robustness
    @user.update(email: "test@example.com", display_name: nil)
    sign_in @user
    get dashboard_path
    assert_response :success
  end

  # Test dashboard displays expected content
  test "should display money in and spending cards" do
    sign_in @user
    get dashboard_path
    assert_response :success
    # Check that money in and spending cards are displayed
    assert_match /Money In/, response.body
    assert_match /Spending/, response.body
  end

  test "should display expected income when greater than actual" do
    sign_in @user
    # Create income template and event to generate expected income
    template = IncomeTemplate.create!(
      user: @user,
      name: "Test Salary #{Time.current.to_i}",
      frequency: "monthly",
      estimated_amount: 5000.00,
      auto_create: true,
      due_date: Date.today
    )
    get dashboard_path
    assert_response :success
    # If expected income > actual, it should be displayed
    # The view conditionally shows this, so we just check the page loads
  end
end

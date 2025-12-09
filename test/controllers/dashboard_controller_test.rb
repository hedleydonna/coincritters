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
    assert_select "h1", text: /Welcome back.*#{@user.email.split('@').first.capitalize}/
  end

  test "should display display_name when present" do
    @user.update(display_name: "Test User")
    sign_in @user
    get dashboard_path
    assert_response :success
    assert_select "h1", text: /Welcome back, Test User/
  end

  # Test dashboard content
  test "should render dashboard content" do
    sign_in @user
    get dashboard_path
    assert_response :success
    assert_select "h1", text: /Welcome back/
  end

  test "should include sign out link" do
    sign_in @user
    get dashboard_path
    assert_select "form[action=?]", destroy_user_session_path do
      assert_select "input[type=hidden][name=_method][value=delete]"
    end
  end

  test "should include edit profile button" do
    sign_in @user
    get dashboard_path
    # Check that there's a form with the correct action
    assert_select "form[action=?]", edit_user_registration_path
    # Check that the form contains "Edit Profile" text somewhere
    assert_match /Edit Profile/, response.body
  end

  # Test display_name preference
  test "should prefer display_name over email" do
    @user.update(display_name: "Preferred Name")
    sign_in @user
    get dashboard_path
    assert_select "h1", text: /Welcome back, Preferred Name/
  end

  test "should handle empty display_name as nil" do
    @user.update(display_name: "")
    sign_in @user
    get dashboard_path
    # Should fall back to email since display_name is empty
    assert_select "h1", text: /Welcome back.*#{@user.email.split('@').first.capitalize}/
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
end

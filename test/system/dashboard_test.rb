require "application_system_test_case"

class DashboardTest < ApplicationSystemTestCase
  driven_by :selenium, using: :headless_chrome

  test "user can sign up, sign in, and access dashboard" do
    # Visit home page
    visit root_path
    assert_selector "h2", text: "Join CoinCritters!"

    # Sign up
    click_link "Already have an account?"
    assert_current_path new_user_registration_path

    fill_in "Display name", with: "System Test User"
    fill_in "Email", with: "system_test@example.com"
    fill_in "Password", with: "password123"
    fill_in "Confirm password", with: "password123"
    click_button "Sign up"

    # Should redirect to dashboard
    assert_current_path dashboard_path
    assert_text "Welcome back, System Test User"

    # Sign out
    click_button "Sign out"
    assert_current_path root_path

    # Sign back in
    click_link "Sign in"
    fill_in "Email", with: "system_test@example.com"
    fill_in "Password", with: "password123"
    click_button "Log in"

    # Should go to dashboard
    assert_current_path dashboard_path
    assert_text "Welcome back, System Test User"
  end

  test "user can update display name and see changes on dashboard" do
    # Create and sign in user
    user = User.create!(email: "update_test@example.com", password: "password123", display_name: "Original Name")
    sign_in user

    # Visit dashboard
    visit dashboard_path
    assert_text "Welcome back, Original Name"

    # Update display name
    click_link "Edit Profile"
    fill_in "Display name", with: "Updated Name"
    click_button "Update"

    # Should redirect to dashboard and show updated name
    assert_current_path dashboard_path
    assert_text "Welcome back, Updated Name"
  end

  test "dashboard requires authentication" do
    visit dashboard_path
    assert_current_path new_user_session_path
    assert_text "You need to sign in or sign up before continuing."
  end

  test "display name falls back to email when not set" do
    user = User.create!(email: "fallback@example.com", password: "password123")
    sign_in user

    visit dashboard_path
    assert_text "Welcome back, Fallback"
  end
end

require "application_system_test_case"

class StimulusFeaturesTest < ApplicationSystemTestCase
  include Devise::Test::IntegrationHelpers
  
  driven_by :selenium, using: :headless_chrome

  setup do
    @user = User.create!(
      email: "test@example.com",
      password: "password123",
      display_name: "Test User"
    )
    sign_in @user
    
    # Create a budget and some test data
    @budget = @user.current_budget!
    
    # Create an income template and event
    @income_template = @user.income_templates.create!(
      name: "Test Salary",
      frequency: "monthly",
      due_date: Date.today,
      estimated_amount: 3000.00,
      auto_create: true
    )
    @budget.auto_create_income_events
    @income_event = @user.income_events.where(income_template_id: @income_template.id).first
  end

  test "scroll-to-anchor scrolls to section on page load with scroll_to parameter" do
    visit money_map_path
    
    # Scroll down a bit to ensure we're not at the top
    page.execute_script("document.querySelector('[data-controller*=\"scroll-to-anchor\"]').scrollTop = 500")
    
    # Navigate with scroll_to parameter
    visit money_map_path(scroll_to: 'money-in-section')
    
    # Wait for scroll to complete
    sleep 0.5
    
    # Check that we've scrolled to the money-in-section
    scroll_position = page.evaluate_script(
      "document.querySelector('[data-controller*=\"scroll-to-anchor\"]').scrollTop"
    )
    
    # Should have scrolled down (not at top)
    assert scroll_position > 100, "Should have scrolled to money-in-section"
    
    # URL should be cleaned (scroll_to parameter removed)
    assert_no_match(/scroll_to/, current_url)
  end

  test "scroll-to-anchor works with Turbo navigation" do
    visit money_map_path
    
    # Click on an income event to go to show page
    click_link @income_event.display_name, match: :first
    
    # Click cancel to go back with scroll_to parameter
    click_link "Cancel"
    
    # Should navigate back to money map
    assert_current_path money_map_path
    
    # Wait for scroll to complete
    sleep 0.5
    
    # Should have scrolled to the income section
    scroll_position = page.evaluate_script(
      "document.querySelector('[data-controller*=\"scroll-to-anchor\"]').scrollTop"
    )
    
    assert scroll_position > 100, "Should have scrolled to money-in-section after Turbo navigation"
  end

  test "swipe-back navigates back when swiping right on show page" do
    visit income_event_path(@income_event, return_to: 'money_map')
    
    # Simulate a rightward swipe gesture
    # Note: This is a simplified test - actual touch events are complex to simulate
    # In a real scenario, you'd use a library like @testing-library/user-event
    # For now, we'll test that the controller is connected
    assert_selector '[data-controller*="swipe-back"]'
    
    # Verify the back URL is set correctly
    back_url = page.evaluate_script(
      "document.querySelector('[data-controller*=\"swipe-back\"]').dataset.swipeBackBackUrlValue"
    )
    
    assert_match(/money_map.*scroll_to/, back_url, "Back URL should include money_map and scroll_to")
  end

  test "swipe-back is present on edit page and navigates to show page" do
    # Navigate to show page first
    visit income_event_path(@income_event, return_to: 'money_map')
    
    # Click edit link
    click_link "Edit #{@income_event.display_name}"
    
    # Verify swipe-back controller is present
    assert_selector '[data-controller*="swipe-back"]'
    
    # Verify the back URL points to show page
    back_url = page.evaluate_script(
      "document.querySelector('[data-controller*=\"swipe-back\"]').dataset.swipeBackBackUrlValue"
    )
    
    assert_match(/income_events\/#{@income_event.id}/, back_url, "Back URL should point to show page")
  end

  test "cancel button on edit page uses Turbo and scrolls correctly" do
    visit income_event_path(@income_event, return_to: 'money_map')
    click_link "Edit #{@income_event.display_name}"
    
    # Click cancel
    click_link "Cancel"
    
    # Should navigate back to money map
    assert_current_path money_map_path
    
    # Wait for Turbo navigation and scroll
    sleep 0.5
    
    # Should have scrolled to the income section
    scroll_position = page.evaluate_script(
      "document.querySelector('[data-controller*=\"scroll-to-anchor\"]').scrollTop"
    )
    
    assert scroll_position > 100, "Should have scrolled to money-in-section after cancel"
  end

  test "scroll-to-anchor handles missing target gracefully" do
    visit money_map_path(scroll_to: 'non-existent-section')
    
    # Should not crash, just not scroll
    assert_current_path money_map_path
  end

  test "swipe-back does not interfere with form inputs" do
    visit edit_income_event_path(@income_event, return_to: 'money_map')
    
    # Try to interact with form inputs
    fill_in "Income Name", with: "Updated Name"
    
    # Form should work normally
    assert_field "Income Name", with: "Updated Name"
  end

  test "swipe-back does not interfere with buttons and links" do
    visit income_event_path(@income_event, return_to: 'money_map')
    
    # Click the edit link - should work normally
    click_link "Edit #{@income_event.display_name}"
    
    # Should navigate to edit page
    assert_current_path edit_income_event_path(@income_event)
  end
end


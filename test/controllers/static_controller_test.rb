require "test_helper"

class StaticControllerTest < ActionDispatch::IntegrationTest
  test "should get credits" do
    get static_credits_url
    assert_response :success
  end
end

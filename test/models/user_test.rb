require "test_helper"

class UserTest < ActiveSupport::TestCase
  # Test fixtures
  test "should have valid fixtures" do
    assert users(:one).valid?
    assert users(:two).valid?
  end

  # Test display_name attribute
  test "should save display_name" do
    user = User.new(email: "test@example.com", password: "password123")
    user.display_name = "Test Display Name"
    assert user.save
    assert_equal "Test Display Name", user.display_name
  end

  test "display_name should be optional" do
    user = User.new(email: "test@example.com", password: "password123")
    assert user.save
    assert_nil user.display_name
  end

  # Test Devise email validation
  test "email should be present" do
    user = User.new(password: "password123")
    assert_not user.valid?
    assert_includes user.errors[:email], "can't be blank"
  end

  test "email should be unique" do
    existing_user = users(:one)
    user = User.new(email: existing_user.email, password: "password123")
    assert_not user.valid?
    assert_includes user.errors[:email], "has already been taken"
  end

  test "email should be properly formatted" do
    user = User.new(email: "invalid-email", password: "password123")
    assert_not user.valid?
    assert_includes user.errors[:email], "is invalid"
  end

  # Test Devise password validation
  test "password should be present" do
    user = User.new(email: "test@example.com")
    assert_not user.valid?
    assert_includes user.errors[:password], "can't be blank"
  end

  test "password should meet minimum length" do
    user = User.new(email: "test@example.com", password: "12345")
    assert_not user.valid?
    assert_includes user.errors[:password], "is too short (minimum is 6 characters)"
  end

  # Test Devise authentication
  test "should authenticate with valid credentials" do
    user = users(:one)
    authenticated_user = User.find_for_authentication(email: user.email)
    assert_equal user, authenticated_user
  end

  # Test Devise password confirmation
  test "password_confirmation should match password" do
    user = User.new(
      email: "test@example.com",
      password: "password123",
      password_confirmation: "different_password"
    )
    assert_not user.valid?
    assert_includes user.errors[:password_confirmation], "doesn't match Password"
  end

  # Test display_name edge cases
  test "display_name can be blank string" do
    user = User.new(email: "test@example.com", password: "password123", display_name: "")
    assert user.save
    assert_equal "", user.display_name
  end

  test "display_name can contain special characters" do
    user = User.new(email: "test@example.com", password: "password123", display_name: "John Doe 🎉")
    assert user.save
    assert_equal "John Doe 🎉", user.display_name
  end

  # Test uniqueness validation
  test "should validate email uniqueness" do
    # Email uniqueness is validated at model level by Devise
    user1 = User.create!(email: "unique@example.com", password: "password123")
    user2 = User.new(email: "unique@example.com", password: "password456")
    assert_not user2.valid?
    assert_includes user2.errors[:email], "has already been taken"
  end
end

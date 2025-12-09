# frozen_string_literal: true

class Admin::DashboardController < Admin::BaseController
  def index
    @user_count = User.count
    @recent_users = User.order(created_at: :desc).limit(5)
  end
end


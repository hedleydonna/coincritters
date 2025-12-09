# frozen_string_literal: true

class Users::RegistrationsController < Devise::RegistrationsController
  before_action :configure_sign_up_params, only: [:create]
  before_action :configure_account_update_params, only: [:update]

  # Override update_resource to allow profile updates without password
  def update_resource(resource, params)
    # Only allow display_name and email updates, no password required
    resource.update_without_password(params.slice(:display_name, :email))
  end

  protected

  def configure_sign_up_params
    devise_parameter_sanitizer.permit(:sign_up, keys: [:display_name, :email, :password, :password_confirmation])
  end

  def configure_account_update_params
    devise_parameter_sanitizer.permit(:account_update, keys: [:display_name, :email])
  end

  def after_update_path_for(resource)
    dashboard_path
  end
end
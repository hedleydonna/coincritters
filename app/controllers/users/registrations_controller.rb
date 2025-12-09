# frozen_string_literal: true

class Users::RegistrationsController < Devise::RegistrationsController
  before_action :configure_account_update_params, only: [:update]

  # GET /resource/sign_up
  # def new
  #   super
  # end

  # POST /resource
  # def create
  #   super
  # end

  # GET /resource/edit
  # def edit
  #   super
  # end

  # PUT /resource
  def update
    Rails.logger.info "=== UPDATE PARAMS: #{params.inspect} ==="
    Rails.logger.info "=== DISPLAY_NAME PARAM: #{params.dig(:user, :display_name)} ==="

    # Skip password validation if only display_name is being updated
    user_params = params[:user] || {}
    Rails.logger.info "=== USER PARAMS: #{user_params.inspect} ==="

    # Check if we're only updating display_name (and possibly empty password fields)
    password_fields = ['password', 'password_confirmation', 'current_password']
    non_password_fields = user_params.keys - password_fields

    # Also check if password fields are empty
    password_fields_empty = password_fields.all? { |field| user_params[field].blank? }

    Rails.logger.info "=== NON PASSWORD FIELDS: #{non_password_fields.inspect} ==="
    Rails.logger.info "=== PASSWORD FIELDS EMPTY: #{password_fields_empty} ==="

    if non_password_fields == ['display_name'] && password_fields_empty
      Rails.logger.info "=== SKIPPING PASSWORD VALIDATION ==="
      resource.skip_password_validation = true
    end

    super
  end

  # DELETE /resource
  # def destroy
  #   super
  # end

  # GET /resource/cancel
  # Forces the session data which is usually expired after sign
  # in to be expired now. This is useful if the user wants to
  # cancel oauth signing in/up in the middle of the process,
  # removing all OAuth session data.
  # def cancel
  #   super
  # end

  # protected

  # If you have extra params to permit, append them to the sanitizer.
  # def configure_sign_up_params
  #   devise_parameter_sanitizer.permit(:sign_up, keys: [:attribute])
  # end

  # If you have extra params to permit, append them to the sanitizer.
  def configure_account_update_params
    devise_parameter_sanitizer.permit(:account_update, keys: [:display_name])
  end

  protected

  # Override password_required? to skip password validation for display_name-only updates
  def password_required?
    return false if params.dig(:user, :display_name).present? && params[:user].keys.all? { |k| ['display_name', 'password', 'password_confirmation', 'current_password'].include?(k) }

    # Check if password fields are all blank when only display_name is present
    user_params = params[:user] || {}
    password_fields = ['password', 'password_confirmation', 'current_password']
    password_fields_empty = password_fields.all? { |field| user_params[field].blank? }

    return false if user_params['display_name'].present? && password_fields_empty

    super
  end

  # The path used after sign up.
  # def after_sign_up_path_for(resource)
  #   super(resource)
  # end

  # The path used after sign up for inactive accounts.
  # def after_inactive_sign_up_path_for(resource)
  #   super(resource)
  # end
end

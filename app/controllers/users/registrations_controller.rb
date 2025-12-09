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

    user_params = params[:user] || {}
    Rails.logger.info "=== USER PARAMS: #{user_params.inspect} ==="

    # If only display_name is being updated and no password fields are filled
    password_fields = ['password', 'password_confirmation', 'current_password']
    non_password_fields = user_params.keys - password_fields
    password_fields_present = password_fields.any? { |field| user_params[field].present? }

    Rails.logger.info "=== NON PASSWORD FIELDS: #{non_password_fields.inspect} ==="
    Rails.logger.info "=== PASSWORD FIELDS PRESENT: #{password_fields_present} ==="

    # Check if this is a display_name-only update
    if non_password_fields.include?('display_name') && !password_fields_present
      # Check if email is unchanged (just submitted as part of form)
      email_unchanged = user_params['email'] == resource.email

      # Allow if only display_name, or display_name + unchanged email
      if non_password_fields == ['display_name'] || (non_password_fields == ['display_name', 'email'] && email_unchanged)
        Rails.logger.info "=== DISPLAY NAME ONLY UPDATE - SKIPPING PASSWORD VALIDATION ==="
        # Remove current_password from params to prevent validation
        params[:user].delete(:current_password) if params[:user]
        resource.skip_password_validation = true
      end
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

  # Override update_resource to handle display_name-only updates without password
  def update_resource(resource, params)
    # Check if display_name is being updated
    password_fields = ['password', 'password_confirmation', 'current_password']
    non_password_fields = params.keys - password_fields
    password_fields_present = password_fields.any? { |field| params[field].present? }

    # Check if email is unchanged
    email_unchanged = params['email'] == resource.email

    # Allow display_name-only updates (with or without unchanged email)
    if non_password_fields.include?('display_name') && !password_fields_present &&
       (non_password_fields == ['display_name'] || (non_password_fields == ['display_name', 'email'] && email_unchanged))
      # Update display_name directly without password validation
      Rails.logger.info "=== USING DIRECT UPDATE FOR DISPLAY_NAME ==="
      resource.update(display_name: params[:display_name])
    else
      # Use default Devise behavior for password/email changes
      Rails.logger.info "=== USING DEVISE DEFAULT UPDATE ==="
      super
    end
  end

  protected

  # Override password_required? to skip password validation for display_name-only updates
  def password_required?
    user_params = params[:user] || {}
    password_fields = ['password', 'password_confirmation', 'current_password']
    non_password_fields = user_params.keys - password_fields
    password_fields_present = password_fields.any? { |field| user_params[field].present? }

    # Skip password validation if only display_name is being updated
    return false if non_password_fields == ['display_name'] && !password_fields_present

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

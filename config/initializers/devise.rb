# frozen_string_literal: true

Devise.setup do |config|
  # Secret key (fallback for local/dev – Render overrides this with RAILS_MASTER_KEY)
  config.secret_key = ENV.fetch("DEVISE_SECRET_KEY") do
    "7b7f47b5728de73593002ba8be9f60aafe36b66f9184080097c89c4ac67aa2ef746cbeb579b57630a5326ad60574a4698fdee2216d6e353cd49994d594100f56"
  end

  # Email "from" address for Devise mailer
  config.mailer_sender = "no-reply@coincritters.onrender.com"

  # Required for ActiveRecord
  require "devise/orm/active_record"

  # Case-insensitive and strip whitespace on email
  config.case_insensitive_keys = [:email]
  config.strip_whitespace_keys = [:email]

  # Skip session storage for http_auth (default, safe to keep)
  config.skip_session_storage = [:http_auth]

  # Password complexity
  config.password_length = 6..128
  config.email_regexp = /\A[^@\s]+@[^@\s]+\z/

  # Bcrypt cost
  config.stretches = Rails.env.test? ? 1 : 12

  # Reset password email valid for 6 hours
  config.reset_password_within = 6.hours

  # Sign out via DELETE (default, safe)
  config.sign_out_via = :delete

  # ──────────────────────────────────────────────────────────────
  # CRITICAL: Hotwire/Turbo compatibility (this fixes the 500 error)
  # ──────────────────────────────────────────────────────────────
  config.responder.error_status = :unprocessable_entity   # ← MUST be present
  config.responder.redirect_status = :see_other          # ← MUST be present

  # Optional nice defaults (feel free to change later)
  config.expire_all_remember_me_on_sign_out = true
  config.reconfirmable = true
end

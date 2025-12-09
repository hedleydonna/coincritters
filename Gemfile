source "https://rubygems.org"
git_source(:github) { |repo| "https://github.com/#{repo}.git" }

# === CORE RAILS ===
gem "rails", "~> 7.1.6"

ruby "3.3.5"

# === DATABASE ===
gem "pg", "~> 1.5.6", platforms: :ruby

# === ASSETS & FRONTEND ===
gem "sprockets-rails"
gem "importmap-rails"
gem "turbo-rails"
gem "stimulus-rails"
gem "tailwindcss-rails"

# === SERVER & PERFORMANCE ===
gem "puma", ">= 5.0"
gem "bootsnap", require: false
gem "jbuilder"

# === AUTH & PAYMENTS ===
gem 'devise'
gem 'pay', '~> 7.0'

# === WINDOWS FIX (harmless on macOS/Linux) ===
gem "tzinfo-data", platforms: %i[ mswin mswin64 mingw x64_mingw jruby ]

# === DEVELOPMENT & TEST ===
group :development, :test do
  gem "debug", platforms: %i[ mri mswin mswin64 mingw x64_mingw ]
end

group :development do
  gem "web-console"
end

group :test do
  gem "capybara"
  gem "selenium-webdriver"
  gem "webdrivers"
end
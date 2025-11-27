#!/usr/bin/env bash
set -e

# Upgrade RubyGems to fix version conflicts (e.g., tailwindcss-rails needs >=3.2.0)
gem update --system 3.4.10 --no-document

# Run the normal Rails build steps
bundle install
bundle exec rake assets:precompile
bundle exec rake assets:clean
bundle exec rails db:migrate

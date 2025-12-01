#!/usr/bin/env bash
set -e

# Suppress DidYouMean deprecation warnings
export RUBYOPT="-W0"

# Upgrade RubyGems to fix version conflicts (e.g., tailwindcss-rails needs >=3.2.0)
gem update --system 3.4.10 --no-document

# Update browserslist database to fix caniuse-lite warnings (if npx is available)
# NOTE: Removed - this is a Rails app, not a Node.js app
# if command -v npx >/dev/null 2>&1; then
#   npx update-browserslist-db@latest --yes
# else
#   echo "npx not found, skipping browserslist update"
# fi

# Clean up any conflicting gem specs
gem cleanup stringio

# Run the normal Rails build steps
bundle install
bundle exec rake assets:precompile
bundle exec rake assets:clean
bundle exec rails db:migrate

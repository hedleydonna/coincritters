# ---- Base image with newer RubyGems already installed ----
FROM ruby:3.3.5-bullseye

# Upgrade RubyGems and Bundler right away
RUN gem update --system 3.4.10 --no-document && \
    gem install bundler -v 2.5.22

# Install system dependencies
RUN apt-get update -qq && apt-get install -y nodejs postgresql-client libvips

# Set work directory
WORKDIR /app

# Copy gems first
COPY Gemfile Gemfile.lock ./

# Install gems (now with correct RubyGems/Bundler versions)
RUN bundle config set --local without 'development test' && \
    bundle install --jobs 4 --retry 3

# Copy the rest of the app
COPY . .

# Precompile assets
RUN bundle exec rails assets:precompile

# Expose port
EXPOSE 3000

# Start the server
CMD ["bundle", "exec", "rails", "server", "-b", "0.0.0.0", "-p", "3000"]

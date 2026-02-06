# Use the official Ruby image
FROM ruby:3.2.2-slim

# Install dependencies (Postgres client, etc.)
RUN apt-get update -qq && apt-get install -y build-essential libpq-dev curl

# Set working directory
WORKDIR /app

# Install gems
COPY Gemfile Gemfile.lock ./
RUN bundle install --without development test

# Copy the rest of the application
COPY . .

# Precompile assets (even if it's an API, Rails might expect it)
# We use a dummy secret key for the build phase
RUN SECRET_KEY_BASE=dummy_for_build RAILS_ENV=production bundle exec rake assets:precompile || true

# Expose port 8080 (Cloud Run's default)
EXPOSE 8080

# The default command (can be overridden by the Cloud Run Job)
CMD ["bundle", "exec", "rails", "server", "-b", "0.0.0.0", "-p", "8080"]
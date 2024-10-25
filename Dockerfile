# Use the official Ruby image with version 3.1
FROM ruby:3.1

# Install dependencies
RUN apt-get update -qq && apt-get install -y \
    build-essential \
    libpq-dev \
    postgresql-client \
    curl \
    git \
    cmake \
    && rm -rf /var/lib/apt/lists/*


# Install Node.js 20.17.0
RUN curl -fsSL https://deb.nodesource.com/setup_20.x | bash - \
    && apt-get install -y nodejs=20.17.0-1nodesource1 \
    && npm install -g yarn

# Install bundler
RUN gem install bundler

# Set up app directory
WORKDIR /app

# Copy Gemfile, Gemfile.lock, and gemfiles directory
COPY Gemfile Gemfile.lock ./
COPY gemfiles/ gemfiles/

# Install gems
RUN bundle install

# Copy the rest of the application code
COPY . .

# Install Node.js dependencies
RUN yarn install

# Install foreman for running Procfile scripts
RUN gem install foreman

# Ensure bin/dev is executable
RUN chmod +x bin/dev

# Expose port 3000 to the host
EXPOSE 3000

# Copy the entrypoint script into the image
COPY entrypoint.sh /usr/bin/
RUN chmod +x /usr/bin/entrypoint.sh

# Use the entrypoint script as the container's entrypoint
ENTRYPOINT ["entrypoint.sh"]

# syntax=docker/dockerfile:1

# ============================================================
# Build stage: compile gems, JS assets, and precompile Rails
# ============================================================
FROM ruby:3.2.8-slim AS build

ARG NODE_MAJOR=20

RUN apt-get update -qq && \
    apt-get install --no-install-recommends -y \
      build-essential \
      curl \
      git \
      gnupg2 \
      libpq-dev \
      libgeos-dev \
      libproj-dev \
      gdal-bin \
      libvips-dev \
      imagemagick \
      libyaml-dev \
      pkg-config && \
    curl -fsSL https://deb.nodesource.com/setup_${NODE_MAJOR}.x | bash - && \
    apt-get install --no-install-recommends -y nodejs && \
    corepack enable && \
    rm -rf /var/lib/apt/lists/*

WORKDIR /app

# ---- Install Ruby dependencies ----
COPY Gemfile Gemfile.lock ./
COPY gemfiles/ gemfiles/

RUN bundle lock --add-platform x86_64-linux aarch64-linux && \
    bundle config set --local deployment true && \
    bundle config set --local without "development test" && \
    bundle config set --local jobs "$(nproc)" && \
    bundle install

# ---- Install JS dependencies and build assets ----
COPY package.json yarn.lock ./
RUN yarn config set ignore-engines true && \
    yarn install --frozen-lockfile

COPY . .

# Set a dummy SECRET_KEY_BASE so assets:precompile can boot Rails
# (production.rb detects this value and uses local storage instead of S3)
ENV SECRET_KEY_BASE=placeholder_for_build \
    RAILS_ENV=production \
    NODE_ENV=production

RUN yarn build && \
    yarn build:css && \
    bundle exec rails assets:precompile

# Remove node_modules after asset compilation (not needed at runtime)
RUN rm -rf node_modules tmp/cache vendor/bundle/ruby/*/cache

# ============================================================
# Runtime stage: slim image with only what's needed to run
# ============================================================
FROM ruby:3.2.8-slim AS runtime

RUN apt-get update -qq && \
    apt-get install --no-install-recommends -y \
      curl \
      libpq5 \
      libgeos-c1v5 \
      libproj25 \
      gdal-bin \
      libvips42 \
      imagemagick \
      libjemalloc2 && \
    rm -rf /var/lib/apt/lists/*

# Use jemalloc for better memory performance
ENV LD_PRELOAD=/usr/lib/x86_64-linux-gnu/libjemalloc.so.2

# Create non-root user
RUN groupadd --system --gid 1000 rails && \
    useradd rails --uid 1000 --gid 1000 --create-home --shell /bin/bash

WORKDIR /app

# Copy built application from build stage
COPY --from=build /usr/local/bundle /usr/local/bundle
COPY --from=build --chown=rails:rails /app /app

# Ensure runtime dirs exist and are writable
RUN mkdir -p tmp/pids tmp/cache tmp/sockets log && \
    chown -R rails:rails tmp log

USER rails

ENV RAILS_ENV=production \
    RAILS_LOG_TO_STDOUT=true \
    RAILS_SERVE_STATIC_FILES=true \
    RUBY_YJIT_ENABLE=1

EXPOSE 3000

CMD ["bundle", "exec", "puma", "-C", "config/puma.rb"]

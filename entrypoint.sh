#!/bin/bash
set -e

# Create the tmp/pids directory if it doesn't exist
mkdir -p tmp/pids

# Remove a potentially pre-existing server.pid for Rails
rm -f /app/tmp/pids/server.pid

# Wait until PostgreSQL is ready
echo "Waiting for PostgreSQL to start..."
until psql -h db -U postgres -c '\q' 2>/dev/null; do
  sleep 1
  echo "Can't reach database, retrying (this shouldn't take more than 30 seconds to find)..."
done

echo "Found PostgreSQL!"

# Create the database if it doesn't exist
echo "Creating database..."
bundle exec rails db:create

# Create PostGIS extension
echo "Creating PostGIS extension..."
psql -h db -U postgres -c "CREATE EXTENSION IF NOT EXISTS postgis;"

# Run database migrations
echo "Running migrations..."
bundle exec rails db:migrate

# Seed the database
echo "Seeding database..."
bundle exec rails db:seed

# Start the Rails server using bin/dev
echo "Starting the Rails server..."
exec ./bin/dev

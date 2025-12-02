#!/bin/bash
set -e

echo "Starting Cambiatus Backend..."

# Load environment variables from .env.production if present and not already loaded
if [ -z "$ENV_LOADED" ] && [ -f "/opt/cambiatus/backend/.env.production" ]; then
    echo "Loading environment from /opt/cambiatus/backend/.env.production"
    # Export all variables defined in the env file
    set -a
    # shellcheck disable=SC1091
    source /opt/cambiatus/backend/.env.production
    set +a
fi

# Check if we're in development (with _build) or production (extracted release)
if [ -f "_build/prod/rel/cambiatus/bin/cambiatus" ]; then
    # Development environment
    RELEASE_PATH="_build/prod/rel/cambiatus/bin/cambiatus"
    echo "Using development release at $RELEASE_PATH"
elif [ -f "bin/cambiatus" ]; then
    # Production environment (extracted release)
    RELEASE_PATH="bin/cambiatus"
    echo "Using production release at $RELEASE_PATH"
else
    echo "Error: Cambiatus binary not found"
    echo "For development: build the release first with 'MIX_ENV=prod mix release'"
    echo "For production: ensure this script is run from the extracted release directory"
    exit 1
fi

# Ensure required environment variables are set
if [ -z "$DATABASE_URL" ]; then
    echo "Error: DATABASE_URL environment variable is required"
    exit 1
fi

if [ -z "$SECRET_KEY_BASE" ]; then
    echo "Error: SECRET_KEY_BASE environment variable is required"
    echo "Generate one with: mix phx.gen.secret"
    exit 1
fi

# Run database migrations if needed
echo "Running database migrations..."
$RELEASE_PATH eval "Cambiatus.Release.migrate()"

echo "Starting Cambiatus server..."

# Start the release
exec $RELEASE_PATH start

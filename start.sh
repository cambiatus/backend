#!/bin/bash
set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}Starting Cambiatus Backend...${NC}"

# Check if release exists
if [ ! -f "_build/prod/rel/cambiatus/bin/cambiatus" ]; then
    echo -e "${RED}Error: Release not found at _build/prod/rel/cambiatus/bin/cambiatus${NC}"
    echo -e "${YELLOW}Please build the release first with: MIX_ENV=prod mix release${NC}"
    exit 1
fi

# Ensure required environment variables are set
if [ -z "$DATABASE_URL" ]; then
    echo -e "${RED}Error: DATABASE_URL environment variable is required${NC}"
    exit 1
fi

if [ -z "$SECRET_KEY_BASE" ]; then
    echo -e "${RED}Error: SECRET_KEY_BASE environment variable is required${NC}"
    echo -e "${YELLOW}Generate one with: mix phx.gen.secret${NC}"
    exit 1
fi

# Check database connectivity
echo -e "${YELLOW}Checking database connectivity...${NC}"
if ! timeout 10 _build/prod/rel/cambiatus/bin/cambiatus eval "Cambiatus.Repo.query!(\"SELECT 1\")" > /dev/null 2>&1; then
    echo -e "${RED}Warning: Could not connect to database. Make sure the database is running and accessible.${NC}"
fi

# Run database migrations if needed
echo -e "${YELLOW}Running database migrations...${NC}"
_build/prod/rel/cambiatus/bin/cambiatus eval "Cambiatus.Release.migrate()"

echo -e "${GREEN}Starting Cambiatus server...${NC}"

# Start the release
exec _build/prod/rel/cambiatus/bin/cambiatus start

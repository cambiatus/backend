#!/bin/bash
set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
DEPLOY_USER="ubuntu"
SERVER_IP=""
DEPLOY_PATH="/opt/cambiatus/backend"
SERVICE_NAME="cambiatus-backend"

echo -e "${BLUE}Cambiatus Backend Deployment Script (Server Build)${NC}"
echo "=================================================="

# Check if server IP is provided
if [ -z "$1" ]; then
    echo -e "${RED}Error: Server IP address is required${NC}"
    echo "Usage: ./deploy.sh <server-ip>"
    echo "Example: ./deploy.sh app.cambiatus.io"
    exit 1
fi

SERVER_IP="$1"

echo -e "${YELLOW}Deploying to: ${SERVER_IP}${NC}"
echo

# Step 1: Upload source code
echo -e "${GREEN}Step 1: Uploading source code...${NC}"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
SOURCE_PACKAGE="cambiatus-source-${TIMESTAMP}.tar.gz"

echo "Creating source package..."
tar --exclude='.git' \
    --exclude='_build' \
    --exclude='deps' \
    --exclude='node_modules' \
    --exclude='*.tar.gz' \
    --exclude='Dockerfile*' \
    --exclude='build*.sh' \
    --exclude='create*.sh' \
    -czf "${SOURCE_PACKAGE}" .

echo "Uploading source package..."
scp "${SOURCE_PACKAGE}" "${DEPLOY_USER}@${SERVER_IP}:/tmp/"

echo -e "${GREEN}✓ Source code uploaded${NC}"
echo

# Step 2: Create remote build and deployment script
echo -e "${GREEN}Step 2: Creating remote deployment script...${NC}"
cat << 'EOF' | ssh "${DEPLOY_USER}@${SERVER_IP}" 'cat > /tmp/remote_build_and_deploy.sh'
#!/bin/bash
set -e

# Source bashrc first to ensure proper environment setup
if [ -f $HOME/.bashrc ]; then
    echo "Sourcing bashrc..."
    source $HOME/.bashrc
fi

# Source ASDF and set up environment
echo "Sourcing ASDF..."
# First ensure we have bash compatibility
if [ "$SHELL" = "/usr/bin/fish" ]; then
    # For fish shell, we need to use bash for the script
    export SHELL=/bin/bash
fi

if [ -f $HOME/.asdf/asdf.sh ]; then
    source $HOME/.asdf/asdf.sh
fi

# Ensure ASDF is in PATH
export PATH="$HOME/.asdf/bin:$HOME/.asdf/shims:$PATH"

# Set ASDF_DIR if not already set
export ASDF_DIR="$HOME/.asdf"

# Source ASDF completions if available
if [ -f $HOME/.asdf/completions/asdf.bash ]; then
    source $HOME/.asdf/completions/asdf.bash
fi

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

PACKAGE_NAME=$1
DEPLOY_PATH=$2
SERVICE_NAME=$3

echo -e "${GREEN}Starting remote deployment...${NC}"

# Verify Elixir installation and set environment variables
echo "ASDF Version: $(asdf --version 2>/dev/null || echo 'ASDF not found')"
echo "Elixir Path: $(which elixir 2>/dev/null || echo 'Elixir not found')"
echo "Mix Path: $(which mix 2>/dev/null || echo 'Mix not found')"
echo "PATH: $PATH"

# Test basic Erlang functionality first
echo "Testing Erlang..."
erl -noshell -eval "io:format(\"Erlang OK~n\"), halt(0)." || echo "Erlang test failed"

# Extract and enter build directory first
echo -e "${YELLOW}Extracting source code...${NC}"
BUILD_DIR="/tmp/cambiatus-build-$(date +%s)"
mkdir -p "${BUILD_DIR}"
cd "${BUILD_DIR}"
tar -xzf "/tmp/${PACKAGE_NAME}"

echo "Working directory: $(pwd)"
echo "Contents: $(ls -la)"

# Verify we have a mix.exs file
if [ ! -f "mix.exs" ]; then
    echo -e "${RED}Error: mix.exs not found in $(pwd)${NC}"
    exit 1
fi

# Set the correct Elixir/Erlang versions using ASDF
echo "Setting Elixir and Erlang versions..."
echo "erlang 28.0" > .tool-versions
echo "elixir 1.18.4-otp-28" >> .tool-versions

# Reshim to ensure the new versions are available
asdf reshim

# Test basic Elixir functionality
echo "Testing Elixir availability..."
which elixir || echo "Elixir not in PATH"
which mix || echo "Mix not in PATH"

# Test Elixir and Mix with verbose error output
echo "Testing Elixir version..."
elixir --version || { echo "Elixir version check failed!"; exit 1; }

echo "Testing Mix version..."
mix --version || { echo "Mix version check failed!"; exit 1; }

# Test basic Elixir functionality
echo "Testing basic Elixir evaluation..."
elixir -e "IO.puts('Elixir basic test successful')" || { echo "Elixir basic test failed!"; exit 1; }

# Set comprehensive environment variables
export MIX_ENV=prod
export LC_ALL=C.UTF-8
export LANG=C.UTF-8

# Step 2: Install dependencies and build on server
echo -e "${YELLOW}Installing dependencies...${NC}"
# Use normal mode for dependency installation to avoid embedded mode issues
MIX_ENV=prod mix deps.get --only prod

echo -e "${YELLOW}Compiling application...${NC}"
MIX_ENV=prod mix compile

echo -e "${YELLOW}Building assets...${NC}"
MIX_ENV=prod mix assets.deploy 2>/dev/null || echo "No assets to deploy"

echo -e "${YELLOW}Creating release...${NC}"
MIX_ENV=prod mix release cambiatus

echo -e "${GREEN}✓ Build completed successfully${NC}"

# Step 3: Stop existing service
echo -e "${YELLOW}Stopping existing service...${NC}"
pm2 stop "${SERVICE_NAME}" 2>/dev/null || echo "Service not running"
pm2 delete "${SERVICE_NAME}" 2>/dev/null || echo "Service not found"

# Step 4: Deploy the new release
echo -e "${YELLOW}Deploying new release...${NC}"
sudo mkdir -p "${DEPLOY_PATH}"
sudo chown -R ${USER}:${USER} "${DEPLOY_PATH}"

# Backup current deployment if it exists
if [ -d "${DEPLOY_PATH}/current" ]; then
    echo "Backing up current deployment..."
    mv "${DEPLOY_PATH}/current" "${DEPLOY_PATH}/backup-$(date +%Y%m%d_%H%M%S)"
fi

# Copy new release
rsync -a "${BUILD_DIR}/_build/prod/rel/cambiatus/" "${DEPLOY_PATH}/current/"

# Use existing ecosystem.config.js from server
if [ -f "${DEPLOY_PATH}/ecosystem.config.js" ]; then
    echo "Using existing ecosystem.config.js from server"
    cp "${DEPLOY_PATH}/ecosystem.config.js" "${DEPLOY_PATH}/current/"
else
    echo "Warning: No existing ecosystem.config.js found at ${DEPLOY_PATH}/ecosystem.config.js"
fi
cp "${BUILD_DIR}/start.sh" "${DEPLOY_PATH}/current/" 2>/dev/null || echo "No start.sh found"
cp "${BUILD_DIR}/start_with_env.sh" "${DEPLOY_PATH}/current/" 2>/dev/null || echo "No start_with_env.sh found"

# Set permissions
chmod +x "${DEPLOY_PATH}/current/bin/cambiatus"
chmod +x "${DEPLOY_PATH}/current/start.sh" "${DEPLOY_PATH}/current/start_with_env.sh" 2>/dev/null || true

echo -e "${GREEN}✓ Release deployed successfully${NC}"

# Step 5: Start service
echo -e "${YELLOW}Starting service...${NC}"
cd "${DEPLOY_PATH}/current"
pm2 start ecosystem.config.js 2>/dev/null || pm2 start bin/cambiatus --name "${SERVICE_NAME}"

echo -e "${GREEN}✓ Service started successfully${NC}"
pm2 status

# Save PM2 configuration
pm2 save
pm2 startup 2>/dev/null || echo "PM2 startup already configured"

# Step 6: Clean up
echo -e "${YELLOW}Cleaning up...${NC}"
rm -rf "${BUILD_DIR}"
rm "/tmp/${PACKAGE_NAME}"

echo -e "${GREEN}✓ Remote deployment completed successfully!${NC}"
EOF

echo -e "${GREEN}✓ Remote script created${NC}"
echo

# Step 3: Execute remote deployment
echo -e "${GREEN}Step 3: Executing remote deployment...${NC}"
ssh "${DEPLOY_USER}@${SERVER_IP}" "chmod +x /tmp/remote_build_and_deploy.sh && SHELL=/bin/bash /bin/bash /tmp/remote_build_and_deploy.sh '${SOURCE_PACKAGE}' '${DEPLOY_PATH}' '${SERVICE_NAME}'"

echo
echo -e "${GREEN}✓ Deployment completed successfully!${NC}"
echo
echo "Next steps:"
echo "1. Check service status: ssh ${DEPLOY_USER}@${SERVER_IP} 'pm2 status'"
echo "2. View logs: ssh ${DEPLOY_USER}@${SERVER_IP} 'pm2 logs ${SERVICE_NAME}'"
echo "3. Monitor service: ssh ${DEPLOY_USER}@${SERVER_IP} 'pm2 monit'"
echo

# Cleanup local files
rm "${SOURCE_PACKAGE}"

echo -e "${BLUE}Deployment script completed!${NC}"

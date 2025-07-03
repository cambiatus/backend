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

echo -e "${BLUE}Cambiatus Backend Deployment Script${NC}"
echo "====================================="

# Check if server IP is provided
if [ -z "$1" ]; then
    echo -e "${RED}Error: Server IP address is required${NC}"
    echo "Usage: ./deploy.sh <server-ip>"
    echo "Example: ./deploy.sh 54.123.45.67"
    exit 1
fi

SERVER_IP="$1"

echo -e "${YELLOW}Deploying to: ${SERVER_IP}${NC}"
echo

# Step 1: Build the release locally
echo -e "${GREEN}Step 1: Building release locally...${NC}"
echo "Cleaning previous builds..."
rm -rf _build/prod

echo "Installing dependencies..."
MIX_ENV=prod mix deps.get --only prod

echo "Compiling application..."
MIX_ENV=prod mix compile

echo "Building assets..."
MIX_ENV=prod mix assets.deploy 2>/dev/null || echo "No assets to deploy (skipping)"

echo "Creating release..."
MIX_ENV=prod mix release

echo -e "${GREEN}✓ Release built successfully${NC}"
echo

# Step 2: Create deployment package
echo -e "${GREEN}Step 2: Creating deployment package...${NC}"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
PACKAGE_NAME="cambiatus-${TIMESTAMP}.tar.gz"

echo "Creating package: ${PACKAGE_NAME}"
tar -czf "${PACKAGE_NAME}" \
    _build/prod/rel/cambiatus \
    ecosystem.config.js \
    start.sh \
    config/runtime.exs

echo -e "${GREEN}✓ Package created: ${PACKAGE_NAME}${NC}"
echo

# Step 3: Upload to server
echo -e "${GREEN}Step 3: Uploading to server...${NC}"
echo "Uploading package..."
scp "${PACKAGE_NAME}" "${DEPLOY_USER}@${SERVER_IP}:/tmp/"

echo "Uploading deployment script..."
cat > /tmp/remote_deploy.sh << 'EOF'
#!/bin/bash
set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

PACKAGE_NAME="$1"
DEPLOY_PATH="$2"
SERVICE_NAME="$3"

echo -e "${GREEN}Starting remote deployment...${NC}"

# Create deployment directory
sudo mkdir -p "${DEPLOY_PATH}"
sudo chown ubuntu:ubuntu "${DEPLOY_PATH}"

# Stop existing service
echo -e "${YELLOW}Stopping existing service...${NC}"
pm2 stop "${SERVICE_NAME}" 2>/dev/null || echo "Service not running"
pm2 delete "${SERVICE_NAME}" 2>/dev/null || echo "Service not found"

# Backup current deployment
if [ -d "${DEPLOY_PATH}/current" ]; then
    echo -e "${YELLOW}Backing up current deployment...${NC}"
    sudo mv "${DEPLOY_PATH}/current" "${DEPLOY_PATH}/backup-$(date +%Y%m%d_%H%M%S)"
fi

# Extract new release
echo -e "${YELLOW}Extracting new release...${NC}"
cd "${DEPLOY_PATH}"
tar -xzf "/tmp/${PACKAGE_NAME}"
mv _build/prod/rel/cambiatus current

# Copy configuration files
cp ecosystem.config.js current/
cp start.sh current/
mkdir -p current/config
cp config/runtime.exs current/config/

# Set permissions
chmod +x current/start.sh
chmod +x current/bin/cambiatus

# Create log directory
sudo mkdir -p /var/log/cambiatus
sudo chown ubuntu:ubuntu /var/log/cambiatus

echo -e "${GREEN}✓ Deployment extracted successfully${NC}"

# Start service with PM2
echo -e "${YELLOW}Starting service with PM2...${NC}"
cd current
pm2 start ecosystem.config.js

echo -e "${GREEN}✓ Service started successfully${NC}"
pm2 status

# Save PM2 configuration
pm2 save
pm2 startup

# Cleanup
rm "/tmp/${PACKAGE_NAME}"

echo -e "${GREEN}✓ Deployment completed successfully!${NC}"
EOF

scp /tmp/remote_deploy.sh "${DEPLOY_USER}@${SERVER_IP}:/tmp/"

echo -e "${GREEN}✓ Files uploaded successfully${NC}"
echo

# Step 4: Execute remote deployment
echo -e "${GREEN}Step 4: Executing remote deployment...${NC}"
ssh "${DEPLOY_USER}@${SERVER_IP}" "chmod +x /tmp/remote_deploy.sh && /tmp/remote_deploy.sh '${PACKAGE_NAME}' '${DEPLOY_PATH}' '${SERVICE_NAME}'"

echo
echo -e "${GREEN}✓ Deployment completed successfully!${NC}"
echo
echo "Next steps:"
echo "1. SSH to your server: ssh ${DEPLOY_USER}@${SERVER_IP}"
echo "2. Set environment variables in ${DEPLOY_PATH}/current/ecosystem.config.js"
echo "3. Restart the service: pm2 restart ${SERVICE_NAME}"
echo "4. Check logs: pm2 logs ${SERVICE_NAME}"
echo "5. Monitor status: pm2 status"
echo

# Cleanup local package
rm "${PACKAGE_NAME}"
rm /tmp/remote_deploy.sh

echo -e "${BLUE}Deployment script completed!${NC}"

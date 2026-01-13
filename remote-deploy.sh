#!/bin/bash

# Remote Deployment Script for Caddy Proxy
# This script deploys the Caddy proxy to a remote Ubuntu host via SSH

set -e

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}======================================"
echo "Caddy Proxy - Remote SSH Deployment"
echo -e "======================================${NC}"
echo ""

# Check if package exists
if [ ! -f "caddy-deploy-FIXED.tar.gz" ]; then
    echo -e "${RED}Error: caddy-deploy-FIXED.tar.gz not found in current directory${NC}"
    echo "Please download the package first"
    exit 1
fi

# Get remote host details
echo -e "${YELLOW}Remote Host Configuration${NC}"
read -p "SSH Host (user@hostname or user@ip): " SSH_HOST
read -p "Deployment directory [/opt/caddy-deploy]: " DEPLOY_DIR
DEPLOY_DIR=${DEPLOY_DIR:-/opt/caddy-deploy}

echo ""
echo -e "${YELLOW}API Configuration${NC}"
read -p "Netskope API URL: " API_URL
read -p "Netskope API Token (base64): " API_TOKEN

echo ""
echo -e "${BLUE}Summary:${NC}"
echo "  SSH Host: $SSH_HOST"
echo "  Deploy Dir: $DEPLOY_DIR"
echo "  Host Port: 5656"
echo ""
read -p "Proceed with deployment? (y/n) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Deployment cancelled"
    exit 0
fi

echo ""
echo -e "${GREEN}[1/6] Uploading deployment package...${NC}"
scp caddy-deploy-FIXED.tar.gz $SSH_HOST:/tmp/
echo -e "${GREEN}✓ Upload complete${NC}"

echo ""
echo -e "${GREEN}[2/6] Connecting to remote host...${NC}"

# Create deployment script to run on remote host
cat > /tmp/deploy-remote.sh << 'EOFSCRIPT'
#!/bin/bash

set -e

DEPLOY_DIR="$1"
API_URL="$2"
API_TOKEN="$3"

echo "[3/6] Installing Docker if needed..."
if ! command -v docker &> /dev/null; then
    echo "Docker not found, installing..."
    curl -fsSL https://get.docker.com -o /tmp/get-docker.sh
    sh /tmp/get-docker.sh
    systemctl enable docker
    systemctl start docker
    echo "✓ Docker installed"
else
    echo "✓ Docker already installed"
fi

# Check for docker compose (prefer plugin, fallback to standalone)
if docker compose version &> /dev/null; then
    COMPOSE_CMD="docker compose"
    echo "✓ Docker Compose plugin already installed"
elif command -v docker-compose &> /dev/null; then
    COMPOSE_CMD="docker-compose"
    echo "✓ Docker Compose standalone already installed"
else
    echo "Installing Docker Compose..."
    COMPOSE_VERSION=$(curl -s https://api.github.com/repos/docker/compose/releases/latest | grep 'tag_name' | cut -d\" -f4)
    curl -L "https://github.com/docker/compose/releases/download/${COMPOSE_VERSION}/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    chmod +x /usr/local/bin/docker-compose
    COMPOSE_CMD="docker-compose"
    echo "✓ Docker Compose installed"
fi

echo "[4/6] Extracting deployment package..."
mkdir -p $(dirname $DEPLOY_DIR)
cd /tmp
tar -xzf caddy-deploy-FIXED.tar.gz
rm -rf $DEPLOY_DIR
mv caddy-deploy $DEPLOY_DIR
cd $DEPLOY_DIR
echo "✓ Package extracted to $DEPLOY_DIR"

echo "[5/6] Configuring deployment..."

# Update docker-compose.yml with API credentials

if [ -n "$API_URL" ]; then
    sed -i "s|API_URL=.*|API_URL=$API_URL|" docker-compose.yml
    echo "✓ Set API URL"
fi

if [ -n "$API_TOKEN" ]; then
    sed -i "s|API_TOKEN=.*|API_TOKEN=$API_TOKEN|" docker-compose.yml
    echo "✓ Set API Token"
fi

echo "[6/6] Starting containers..."
$COMPOSE_CMD up -d

echo ""
echo "Waiting for services to become healthy..."
MAX_WAIT=60
WAIT_TIME=0
while [ $WAIT_TIME -lt $MAX_WAIT ]; do
    if docker ps --filter "name=caddy-server" --filter "health=healthy" --format "{{.Names}}" | grep -q "caddy-server" && \
       docker ps --filter "name=block-handler" --filter "health=healthy" --format "{{.Names}}" | grep -q "block-handler"; then
        echo "✓ All services are healthy"
        break
    fi
    sleep 2
    WAIT_TIME=$((WAIT_TIME + 2))
    echo -n "."
done
echo ""

if [ $WAIT_TIME -ge $MAX_WAIT ]; then
    echo "⚠ Warning: Services may not be fully healthy yet"
fi

echo ""
echo "======================================"
echo "Deployment Status"
echo "======================================"
$COMPOSE_CMD ps

echo ""
if docker exec caddy-server wget -q -O- http://block-handler:3000/health >/dev/null 2>&1; then
    echo "✓ Internal connectivity OK"
else
    echo "⚠ Warning: Internal connectivity check failed"
fi

echo ""
echo "======================================"
echo "Deployment Complete!"
echo "======================================"
echo "Host Port: 5656"
echo "Configuration: $DEPLOY_DIR/docker-compose.yml"
echo ""
echo "Test with:"
echo "  curl -k https://example.com:5656"
echo ""
echo "View logs:"
echo "  cd $DEPLOY_DIR && $COMPOSE_CMD logs -f"
echo ""
EOFSCRIPT

# Upload the deployment script
scp /tmp/deploy-remote.sh $SSH_HOST:/tmp/
rm /tmp/deploy-remote.sh

# Execute remote deployment
ssh -t $SSH_HOST "sudo bash /tmp/deploy-remote.sh '$DEPLOY_DIR' '$API_URL' '$API_TOKEN'"

echo ""
echo -e "${GREEN}======================================"
echo "Remote Deployment Complete!"
echo -e "======================================${NC}"
echo ""
echo "Your Caddy proxy is now running on $SSH_HOST"
echo "Access on port: 5656"
echo ""
echo "Next steps:"
echo "  1. Test: curl -k https://test.com:5656"
echo "  2. View logs: ssh $SSH_HOST 'cd $DEPLOY_DIR && $COMPOSE_CMD logs -f'"
echo "  3. Customize block page: ssh $SSH_HOST and edit $DEPLOY_DIR/block-handler/blocked.html"
echo ""

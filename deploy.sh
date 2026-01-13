#!/bin/bash

# Caddy Proxy Deployment Script
# This script helps deploy the Caddy reverse proxy with Netskope integration

set -e  # Exit on error

echo "======================================"
echo "Caddy Proxy Deployment Script"
echo "======================================"
echo ""

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check if running as root
if [ "$EUID" -ne 0 ] && ! groups | grep -q docker; then 
    echo -e "${YELLOW}Warning: Not running as root or in docker group. You may need sudo for docker commands.${NC}"
fi

# Function to print status messages
print_status() {
    echo -e "${GREEN}[✓]${NC} $1"
}

print_error() {
    echo -e "${RED}[✗]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[!]${NC} $1"
}

# Check prerequisites
echo "Checking prerequisites..."

# Check Docker
if ! command -v docker &> /dev/null; then
    print_error "Docker is not installed. Please install Docker first."
    exit 1
fi
print_status "Docker is installed"

# Check Docker Compose (prefer newer docker compose plugin)
if docker compose version &> /dev/null; then
    COMPOSE_CMD="docker compose"
    print_status "Docker Compose plugin is installed"
elif command -v docker-compose &> /dev/null; then
    COMPOSE_CMD="docker-compose"
    print_warning "Using legacy docker-compose command (consider upgrading to docker compose plugin)"
else
    print_error "Docker Compose is not installed. Please install Docker Compose first."
    exit 1
fi

# Check if containers are already running
echo ""
echo "Checking for existing containers..."
if docker ps -a | grep -q "caddy-server\|block-handler"; then
    print_warning "Existing containers found"
    read -p "Would you like to remove them and start fresh? (y/n) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo "Stopping and removing containers..."
        $COMPOSE_CMD down
        print_status "Containers removed"
    fi
fi

# Deploy
echo ""
echo "======================================"
echo "Starting deployment..."
echo "======================================"
echo ""

echo "Pulling latest images..."
$COMPOSE_CMD pull

echo ""
echo "Starting services..."
$COMPOSE_CMD up -d

echo ""
echo "Waiting for services to become healthy..."
MAX_WAIT=60
WAIT_TIME=0
while [ $WAIT_TIME -lt $MAX_WAIT ]; do
    if docker ps --filter "name=caddy-server" --filter "health=healthy" --format "{{.Names}}" | grep -q "caddy-server" && \
       docker ps --filter "name=block-handler" --filter "health=healthy" --format "{{.Names}}" | grep -q "block-handler"; then
        print_status "All services are healthy"
        break
    fi
    sleep 2
    WAIT_TIME=$((WAIT_TIME + 2))
    echo -n "."
done
echo ""

if [ $WAIT_TIME -ge $MAX_WAIT ]; then
    print_warning "Services may not be fully healthy yet. Check logs with: $COMPOSE_CMD logs"
fi

# Check status
echo ""
echo "======================================"
echo "Deployment Status"
echo "======================================"
echo ""

if docker ps | grep -q "caddy-server"; then
    HEALTH_STATUS=$(docker inspect --format='{{.State.Health.Status}}' caddy-server 2>/dev/null || echo "unknown")
    if [ "$HEALTH_STATUS" = "healthy" ]; then
        print_status "Caddy server is running and healthy"
    elif [ "$HEALTH_STATUS" = "starting" ]; then
        print_warning "Caddy server is running but still starting up"
    else
        print_status "Caddy server is running (health: $HEALTH_STATUS)"
    fi
else
    print_error "Caddy server failed to start"
    echo "Check logs with: $COMPOSE_CMD logs caddy"
fi

if docker ps | grep -q "block-handler"; then
    HEALTH_STATUS=$(docker inspect --format='{{.State.Health.Status}}' block-handler 2>/dev/null || echo "unknown")
    if [ "$HEALTH_STATUS" = "healthy" ]; then
        print_status "Block handler is running and healthy"
    elif [ "$HEALTH_STATUS" = "starting" ]; then
        print_warning "Block handler is running but still starting up"
    else
        print_status "Block handler is running (health: $HEALTH_STATUS)"
    fi
else
    print_error "Block handler failed to start"
    echo "Check logs with: $COMPOSE_CMD logs block-handler"
fi

echo ""
echo "======================================"
echo "Deployment Complete!"
echo "======================================"
echo ""
echo "Services are running on:"
echo "  - HTTPS: port 5656"
echo "  - Admin: port 2019"
echo ""
echo "Useful commands:"
echo "  View logs:     $COMPOSE_CMD logs -f"
echo "  Stop services: $COMPOSE_CMD down"
echo "  Restart:       $COMPOSE_CMD restart"
echo "  Status:        $COMPOSE_CMD ps"
echo ""
echo "To test the proxy:"
echo "  curl -k https://example.com:5656"
echo "  or configure clients to use this host on port 5656"
echo ""

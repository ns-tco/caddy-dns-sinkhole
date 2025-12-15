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

# Check Docker Compose
if ! command -v docker-compose &> /dev/null && ! docker compose version &> /dev/null; then
    print_error "Docker Compose is not installed. Please install Docker Compose first."
    exit 1
fi
print_status "Docker Compose is installed"

# Check if containers are already running
echo ""
echo "Checking for existing containers..."
if docker ps -a | grep -q "caddy-server\|block-handler"; then
    print_warning "Existing containers found"
    read -p "Would you like to remove them and start fresh? (y/n) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo "Stopping and removing containers..."
        docker-compose down
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
docker-compose pull

echo ""
echo "Starting services..."
docker-compose up -d

echo ""
echo "Waiting for services to start..."
sleep 5

# Check status
echo ""
echo "======================================"
echo "Deployment Status"
echo "======================================"
echo ""

if docker ps | grep -q "caddy-server"; then
    print_status "Caddy server is running"
else
    print_error "Caddy server failed to start"
    echo "Check logs with: docker-compose logs caddy"
fi

if docker ps | grep -q "block-handler"; then
    print_status "Block handler is running"
else
    print_error "Block handler failed to start"
    echo "Check logs with: docker-compose logs block-handler"
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
echo "  View logs:     docker-compose logs -f"
echo "  Stop services: docker-compose down"
echo "  Restart:       docker-compose restart"
echo ""
echo "To test the proxy:"
echo "  curl -k https://example.com:5656"
echo "  or configure clients to use this host on port 5656"
echo ""

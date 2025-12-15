# SSH Deployment Guide - Ubuntu Host

This guide walks you through deploying the Caddy proxy to an Ubuntu host via SSH.

## Prerequisites

### On Your Local Machine
- SSH client installed
- The deployment package: `caddy-deploy-FIXED.tar.gz`
- SSH access credentials to your Ubuntu host

### On Ubuntu Host
- Ubuntu 20.04 or newer
- Docker installed (we can install if needed)
- Docker Compose installed (we can install if needed)
- SSH server running
- Sudo/root access

## Deployment Methods

### Method 1: Fully Automated (Recommended)

Use the automated deployment script that handles everything including Docker installation.

### Method 2: Manual Step-by-Step

Follow the manual steps for more control over the process.

---

## Method 1: Fully Automated Deployment

### Step 1: Upload the Package

From your local machine:

```bash
# Upload the deployment package
scp caddy-deploy-FIXED.tar.gz user@your-ubuntu-host:/tmp/

# Example:
# scp caddy-deploy-FIXED.tar.gz root@192.168.1.100:/tmp/
```

### Step 2: Connect via SSH

```bash
ssh user@your-ubuntu-host

# Example:
# ssh root@192.168.1.100
```

### Step 3: Run Auto-Deploy Script

```bash
# Extract the package
cd /tmp
tar -xzf caddy-deploy-FIXED.tar.gz
cd caddy-deploy

# Run the automated deployment
sudo ./deploy.sh
```

The script will:
- ✓ Check for Docker/Docker Compose
- ✓ Create macvlan network if needed
- ✓ Start the containers
- ✓ Verify deployment

### Step 4: Configure

Before or after running deploy.sh, edit the configuration:

```bash
nano docker-compose.yml

# Update these lines:
# Line 11: ipv4_address (your desired IP)
# Lines 43-44: API credentials
```

Then restart:
```bash
sudo docker-compose restart
```

---

## Method 2: Manual Step-by-Step Deployment

### Step 1: Prepare Ubuntu Host

Connect to your Ubuntu host:

```bash
ssh user@your-ubuntu-host
```

### Step 2: Install Docker (if not installed)

```bash
# Update package index
sudo apt-get update

# Install dependencies
sudo apt-get install -y \
    ca-certificates \
    curl \
    gnupg \
    lsb-release

# Add Docker's official GPG key
sudo mkdir -p /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg

# Set up Docker repository
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

# Install Docker
sudo apt-get update
sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin

# Verify installation
sudo docker --version
sudo docker compose version
```

### Step 3: (Optional) Add User to Docker Group

```bash
# Add your user to docker group (avoid needing sudo)
sudo usermod -aG docker $USER

# Log out and back in for changes to take effect
exit
ssh user@your-ubuntu-host

# Verify
docker ps
```

### Step 4: Upload Deployment Package

From your LOCAL machine (in a new terminal):

```bash
# Upload the package
scp caddy-deploy-FIXED.tar.gz user@your-ubuntu-host:~/

# Example with specific path:
# scp caddy-deploy-FIXED.tar.gz root@192.168.1.100:/opt/
```

### Step 5: Extract and Configure

Back on the Ubuntu host:

```bash
# Extract the package
cd ~
tar -xzf caddy-deploy-FIXED.tar.gz
cd caddy-deploy

# Or if you uploaded to /opt:
# cd /opt
# tar -xzf caddy-deploy-FIXED.tar.gz
# cd caddy-deploy

# Edit configuration
nano docker-compose.yml
```

**Required changes in docker-compose.yml:**

1. **Line 11** - Set your IP address:
   ```yaml
   ipv4_address: 192.168.53.46  # Change to available IP on your network
   ```

2. **Lines 43-44** - Set API credentials:
   ```yaml
   - API_URL=https://your-instance.goskope.com/api/v2/nsiq/urllookup
   - API_TOKEN=your_base64_encoded_token
   ```

3. **Line 21** - (Optional) Set timezone:
   ```yaml
   - TZ=America/Chicago  # Change to your timezone
   ```

Save and exit (Ctrl+X, Y, Enter in nano)

### Step 6: Find Your Network Interface

```bash
# List network interfaces
ip link show

# Common names: eth0, ens33, ens160, enp0s3
# Note the name - you'll need it for the next step
```

### Step 7: Create macvlan Network

```bash
# Create the macvlan network
# Replace values with your network settings:

sudo docker network create -d macvlan \
  --subnet=192.168.53.0/24 \
  --gateway=192.168.53.1 \
  -o parent=eth0 \
  macvlan_42

# Example for different network:
# sudo docker network create -d macvlan \
#   --subnet=10.0.1.0/24 \
#   --gateway=10.0.1.1 \
#   -o parent=ens33 \
#   macvlan_42

# Verify
sudo docker network ls | grep macvlan
```

**Network Settings Guide:**
- `--subnet`: Your network's subnet (check with `ip addr`)
- `--gateway`: Your router/gateway IP
- `-o parent`: Your network interface name (from Step 6)

### Step 8: Deploy

```bash
# Start the containers
sudo docker-compose up -d

# Or without sudo if you added user to docker group:
# docker-compose up -d

# Wait a few seconds for containers to start
```

### Step 9: Verify Deployment

```bash
# Check container status
sudo docker-compose ps

# Both containers should show "Up"
# caddy-server    ... Up
# block-handler   ... Up

# Check logs
sudo docker-compose logs

# Test internal connectivity
sudo docker exec caddy-server wget -q -O- http://block-handler:3000

# Should return HTML, not an error

# View real-time logs
sudo docker-compose logs -f
# (Ctrl+C to exit)
```

### Step 10: Test from Client

From your local machine or another device:

```bash
# Test the proxy
curl -k https://example.com --resolve example.com:443:192.168.53.46

# Replace 192.168.53.46 with your Caddy IP
```

You should see the block page HTML!

---

## Post-Deployment

### Make it Persistent

To ensure containers start on boot:

```bash
cd ~/caddy-deploy  # or /opt/caddy-deploy

# Containers already have restart: unless-stopped
# But verify docker service starts on boot:
sudo systemctl enable docker
```

### Useful Commands

```bash
# View logs
sudo docker-compose logs -f

# Restart services
sudo docker-compose restart

# Stop services
sudo docker-compose down

# Start services
sudo docker-compose up -d

# View container status
sudo docker-compose ps

# Update containers
sudo docker-compose pull
sudo docker-compose up -d
```

### Firewall Configuration

If you have UFW or iptables enabled:

```bash
# Allow HTTP/HTTPS if needed
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp
sudo ufw allow 443/udp  # For HTTP/3

# Or for specific interface
sudo ufw allow in on eth0 to any port 443
```

---

## Troubleshooting SSH Deployment

### Issue: Permission Denied

```bash
# Solution 1: Use sudo
sudo docker-compose up -d

# Solution 2: Add user to docker group
sudo usermod -aG docker $USER
# Log out and back in
```

### Issue: Network Not Found

```bash
# Create the network first
sudo docker network create -d macvlan \
  --subnet=YOUR_SUBNET \
  --gateway=YOUR_GATEWAY \
  -o parent=YOUR_INTERFACE \
  macvlan_42
```

### Issue: Port Already in Use

```bash
# Check what's using the ports
sudo netstat -tlnp | grep -E ':(80|443|2019)'

# Or
sudo ss -tlnp | grep -E ':(80|443|2019)'

# Stop conflicting service
sudo systemctl stop apache2  # or nginx, or whatever
sudo systemctl disable apache2
```

### Issue: Can't Connect from Other Devices

```bash
# Check if containers are running
sudo docker-compose ps

# Check firewall
sudo ufw status

# Verify IP is correct
ip addr show

# Test locally first
curl -k https://localhost --resolve localhost:443:192.168.53.46
```

### Issue: 502 Error

```bash
# Run troubleshooting script
cd ~/caddy-deploy
chmod +x troubleshoot-502.sh
sudo ./troubleshoot-502.sh

# Or check manually
sudo docker exec caddy-server wget -q -O- http://block-handler:3000
```

---

## One-Liner Deployment

If Docker is already installed and configured:

```bash
# Upload, extract, configure, deploy
scp caddy-deploy-FIXED.tar.gz user@host:/tmp/ && \
ssh user@host "cd /tmp && tar -xzf caddy-deploy-FIXED.tar.gz && cd caddy-deploy && \
sudo docker network create -d macvlan --subnet=192.168.53.0/24 --gateway=192.168.53.1 -o parent=eth0 macvlan_42 ; \
sudo docker-compose up -d"
```

(Still need to edit docker-compose.yml for your IP and API credentials!)

---

## Complete Automated Script

Save this as `remote-deploy.sh` on your local machine:

```bash
#!/bin/bash

# Remote deployment script
HOST="user@your-ubuntu-host"
DEPLOY_DIR="/opt/caddy-deploy"

echo "Uploading deployment package..."
scp caddy-deploy-FIXED.tar.gz $HOST:/tmp/

echo "Deploying to remote host..."
ssh $HOST << 'ENDSSH'
# Extract
cd /tmp
tar -xzf caddy-deploy-FIXED.tar.gz
sudo mv caddy-deploy /opt/
cd /opt/caddy-deploy

# Install Docker if needed
if ! command -v docker &> /dev/null; then
    echo "Installing Docker..."
    curl -fsSL https://get.docker.com -o get-docker.sh
    sudo sh get-docker.sh
    sudo systemctl enable docker
    sudo systemctl start docker
fi

# Run deployment
sudo ./deploy.sh

echo "Deployment complete!"
echo "Remember to edit /opt/caddy-deploy/docker-compose.yml"
echo "Then run: cd /opt/caddy-deploy && sudo docker-compose restart"
ENDSSH

echo "Done! SSH into the host to configure docker-compose.yml"
```

---

## Security Recommendations

1. **Use SSH Keys** instead of passwords:
   ```bash
   ssh-copy-id user@your-ubuntu-host
   ```

2. **Secure Docker Socket**:
   ```bash
   sudo chmod 660 /var/run/docker.sock
   ```

3. **Enable Firewall**:
   ```bash
   sudo ufw enable
   sudo ufw allow ssh
   sudo ufw allow 443/tcp
   ```

4. **Secure API Credentials**:
   - Consider using Docker secrets
   - Don't commit credentials to version control

5. **Regular Updates**:
   ```bash
   sudo apt-get update && sudo apt-get upgrade -y
   sudo docker-compose pull
   sudo docker-compose up -d
   ```

---

## Summary

**Fastest Deployment:**
1. Upload package via SCP
2. SSH into host
3. Extract and run `./deploy.sh`
4. Edit docker-compose.yml
5. Restart containers

**Time Required:**
- With Docker installed: ~5 minutes
- Without Docker: ~10-15 minutes

**What You Need:**
- SSH access to Ubuntu host
- Network details (subnet, gateway, interface)
- API credentials
- Available IP address

The deployment is straightforward and well-documented. All the tools are in the package!

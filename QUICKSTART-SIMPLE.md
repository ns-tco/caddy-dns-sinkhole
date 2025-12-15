# Simplified Deployment - Port 5656

This is a simplified version of the Caddy proxy that uses standard Docker networking and responds on port 5656.

## ✨ What Changed

**SIMPLIFIED:**
- ❌ No macvlan network needed
- ❌ No IP address configuration needed
- ❌ No network interface detection needed
- ✅ Simple bridge network (automatic)
- ✅ Host responds on port 5656
- ✅ Much easier to deploy!

## 🚀 Quick Deploy

### Local Deployment

```bash
# 1. Extract
tar -xzf caddy-deploy-SIMPLE.tar.gz
cd caddy-deploy

# 2. Edit configuration (OPTIONAL)
nano docker-compose.yml
# Lines 39-40: Update API credentials if needed

# 3. Deploy
docker-compose up -d

# 4. Test
curl -k https://example.com:5656
```

That's it! No network configuration needed.

### SSH Deployment

```bash
# 1. Upload
scp caddy-deploy-SIMPLE.tar.gz user@ubuntu-host:/tmp/

# 2. SSH and deploy
ssh user@ubuntu-host
cd /tmp
tar -xzf caddy-deploy-SIMPLE.tar.gz
cd caddy-deploy
docker-compose up -d

# 3. Test
curl -k https://example.com:5656
```

## 📋 Configuration

Only ONE thing to configure (optional):

### API Credentials (docker-compose.yml, lines 39-40)
```yaml
- API_URL=https://nskp-io.goskope.com/api/v2/nsiq/urllookup
- API_TOKEN=cmJhY3YzOm5haWthRzRDcnlySTg2dnIwZnNqMg==
```

Everything else works out of the box!

## 🌐 Network Architecture

**Before (Complex):**
```
Client → macvlan network → Caddy (IP: 192.168.53.46) → bridge → block-handler
         ↑ Required manual network config
```

**Now (Simple):**
```
Client → Host:5656 → Docker bridge → Caddy:443 → block-handler:3000
         ↑ Automatic, no config needed
```

## 🔌 Port Mapping

- **Host Port 5656** → Caddy Container Port 443 (HTTPS)
- **Host Port 2019** → Caddy Admin API

Access from anywhere:
- `https://your-host:5656`
- `https://192.168.1.100:5656`
- `https://server.example.com:5656`

## ✅ Testing

### From Local Machine
```bash
curl -k https://localhost:5656
```

### From Another Machine
```bash
curl -k https://your-host-ip:5656
curl -k https://example.com:5656
```

### With Browser
```
https://your-host-ip:5656
```

(Accept self-signed certificate warning)

## 🛠️ Management

### View Logs
```bash
docker-compose logs -f
```

### Restart
```bash
docker-compose restart
```

### Stop
```bash
docker-compose down
```

### Start
```bash
docker-compose up -d
```

### Update
```bash
docker-compose pull
docker-compose up -d
```

## 🎯 Use Cases

### As Forward Proxy
Configure clients to use `your-host:5656` as HTTPS proxy

### As Reverse Proxy
Point DNS/load balancer to `your-host:5656`

### For Testing
Direct connections: `https://any-domain:5656`

## 🔒 Firewall

If you have a firewall, allow port 5656:

### UFW (Ubuntu)
```bash
sudo ufw allow 5656/tcp
sudo ufw allow 5656/udp
```

### iptables
```bash
sudo iptables -A INPUT -p tcp --dport 5656 -j ACCEPT
sudo iptables -A INPUT -p udp --dport 5656 -j ACCEPT
```

### firewalld
```bash
sudo firewall-cmd --add-port=5656/tcp --permanent
sudo firewall-cmd --add-port=5656/udp --permanent
sudo firewall-cmd --reload
```

## 📊 Verification

```bash
# Check containers are running
docker-compose ps

# Should show:
# caddy-server    Up   0.0.0.0:5656->443/tcp, ...
# block-handler   Up

# Test internal connectivity
docker exec caddy-server wget -q -O- http://block-handler:3000

# Should return HTML

# Test external access
curl -k https://localhost:5656

# Should show block page
```

## 🐛 Troubleshooting

### Port already in use
```bash
# Check what's using port 5656
sudo netstat -tlnp | grep 5656
# or
sudo ss -tlnp | grep 5656

# Stop the conflicting service or change port in docker-compose.yml
```

### Can't connect from other machines
```bash
# Check firewall
sudo ufw status

# Check if container is listening
docker-compose ps

# Check if port is bound
sudo netstat -tlnp | grep 5656
```

### 502 Error
```bash
# Check both containers are running
docker-compose ps

# Check logs
docker-compose logs

# Verify internal connectivity
docker exec caddy-server wget -q -O- http://block-handler:3000
```

## 🎨 Customization

### Change Port
Edit `docker-compose.yml` line 21:
```yaml
ports:
  - "8080:443"  # Use port 8080 instead
```

### Change Timezone
Edit `docker-compose.yml` line 19:
```yaml
- TZ=America/New_York
```

### Customize Block Page
Edit `block-handler/blocked.html`

## 🔄 Migration from Old Version

If you deployed the macvlan version:

```bash
# Stop old deployment
docker-compose down

# Remove macvlan network (optional)
docker network rm macvlan_42

# Deploy new version
# Extract new package and deploy as above
```

## 📖 Documentation

- **QUICKSTART-SIMPLE.md** - This file
- **README.md** - Complete documentation
- **502-FIX.md** - Network troubleshooting
- **SSH-DEPLOYMENT.md** - SSH deployment guide (updated)

## ✅ Benefits of Simplified Version

- ✅ No network configuration needed
- ✅ No IP address management
- ✅ Works on any Docker host
- ✅ Easy to understand
- ✅ Easy to debug
- ✅ Portable (same config on any host)
- ✅ Standard Docker practices

## 🎯 Summary

**Old Way:**
- Configure macvlan network
- Set subnet, gateway, interface
- Assign static IP
- Complex troubleshooting

**New Way:**
- Extract package
- Run `docker-compose up -d`
- Access on port 5656
- Done!

**Deployment time: ~2 minutes**

This is the recommended deployment method for most users!

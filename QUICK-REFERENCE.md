# Caddy Proxy - Quick Reference Card

## 🎯 Essential Commands

| Task | Command |
|------|---------|
| **Start** | `docker-compose up -d` |
| **Stop** | `docker-compose down` |
| **Restart** | `docker-compose restart` |
| **Logs** | `docker-compose logs -f` |
| **Status** | `docker-compose ps` |
| **Update** | `docker-compose pull && docker-compose up -d` |

## 📝 Configuration Files

| File | Purpose |
|------|---------|
| `docker-compose.yml` | Main configuration |
| `caddy_config/Caddyfile` | Proxy rules |
| `block-handler/server.js` | API handler |
| `block-handler/blocked.html` | Block page |

## 🔧 Key Configuration Points

### 1. IP Address (docker-compose.yml, line 11)
```yaml
ipv4_address: 192.168.53.46
```

### 2. API Settings (docker-compose.yml, lines 41-42)
```yaml
- API_URL=https://nskp-io.goskope.com/api/v2/nsiq/urllookup
- API_TOKEN=cmJhY3YzOm5haWthRzRDcnlySTg2dnIwZnNqMg==
```

### 3. Timezone (docker-compose.yml, line 20)
```yaml
- TZ=America/Chicago
```

## 🌐 Network Setup

```bash
docker network create -d macvlan \
  --subnet=192.168.53.0/24 \
  --gateway=192.168.53.1 \
  -o parent=eth0 \
  macvlan_42
```

## 🚀 Deploy

```bash
# Method 1: Automated
./deploy.sh

# Method 2: Manual
docker-compose up -d
```

## 🧪 Test

```bash
# Test with curl
curl -k https://example.com --resolve example.com:443:192.168.53.46

# Check services
docker-compose ps

# View logs
docker-compose logs -f
```

## 🔍 Troubleshooting

| Problem | Solution |
|---------|----------|
| **Network not found** | Create macvlan network (see above) |
| **IP in use** | Change IP in docker-compose.yml |
| **Services won't start** | Check logs: `docker-compose logs` |
| **API errors** | Verify credentials in docker-compose.yml |
| **Certificate errors** | Clear certs: `rm -rf data/caddy/certificates` |

## 📂 Directory Structure

```
caddy-deploy/
├── docker-compose.yml          # Main config
├── deploy.sh                   # Deploy script
├── caddy_config/
│   └── Caddyfile              # Proxy config
├── block-handler/
│   ├── server.js              # API handler
│   ├── blocked.html           # Block page
│   └── package.json
├── data/                      # Runtime data
├── config/                    # Caddy config
└── [docs]/                    # Documentation files
```

## 🔒 Ports

- **80**: HTTP
- **443**: HTTPS (TCP + UDP)
- **2019**: Admin API

## 📊 Monitoring

```bash
# Real-time logs
docker-compose logs -f

# Specific service
docker-compose logs -f caddy
docker-compose logs -f block-handler

# Container stats
docker stats caddy-server block-handler
```

## 🛠️ Maintenance

```bash
# Backup configuration
tar -czf backup-$(date +%Y%m%d).tar.gz caddy_config/ block-handler/

# Update images
docker-compose pull
docker-compose up -d

# Clean up old data
docker-compose down
rm -rf data/ config/
docker-compose up -d
```

## 📖 Documentation

- **QUICKSTART.md** - Fast deployment guide
- **README.md** - Complete documentation  
- **DEPLOYMENT-CHECKLIST.md** - Pre-flight checklist
- **DEPLOYMENT-SUMMARY.md** - Package overview

## 🆘 Emergency Commands

```bash
# Force restart everything
docker-compose down && docker-compose up -d

# View all logs
docker-compose logs --tail=100

# Remove and rebuild
docker-compose down -v
docker-compose up -d

# Check network
docker network inspect macvlan_42
```

## ✅ Post-Deploy Verification

- [ ] Both containers running (`docker-compose ps`)
- [ ] No errors in logs
- [ ] Test request shows block page
- [ ] Categories display correctly
- [ ] API calls succeeding

---

**Need More Info?** See README.md for full documentation

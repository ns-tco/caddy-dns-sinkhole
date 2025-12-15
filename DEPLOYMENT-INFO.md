# Deployment Information

## 🌐 Public Access

Your Caddy DNS sinkhole is accessible from the internet at:

**Public IP:** `173.167.175.162`
**Port:** `443` (HTTPS)
**URL:** `https://173.167.175.162`

### How It Works

1. **Internet → Public IP:443**
2. **Port Forwarding → Host:443**
3. **Docker Port Mapping → Container:443 (Caddy)**
4. **Reverse Proxy → Container:3000 (Block Handler)**
5. **Block Handler → Netskope API**
6. **Response → Branded Block Page**

---

## 🔒 Certificate Authority

**CA Name:** nskp.io
**Root Certificate:** `/home/tco/caddy-deploy/nskp-io-root-ca.crt`

### Certificate Details
- **Subject:** CN=nskp.io Root CA
- **Issuer:** CN=nskp.io Root CA (self-signed)
- **Valid From:** 2025-12-15
- **Valid Until:** 2035-10-24 (10 years)
- **Algorithm:** ECC (Elliptic Curve)

### For Clients to Trust This CA

Clients connecting to `https://173.167.175.162` will see `ERR_SSL_PROTOCOL_ERROR` or certificate warnings until they install the root CA certificate.

**Installation Guide:** See [INSTALL-CA-CERTIFICATE.md](INSTALL-CA-CERTIFICATE.md)

---

## 🐳 Docker Configuration

### Container Ports

```yaml
# External access on standard HTTPS port
0.0.0.0:443 → Container:443

# Local testing access
0.0.0.0:5656 → Container:443
```

### Services

| Service | Container | Image | Ports |
|---------|-----------|-------|-------|
| Caddy | caddy-server | caddy:latest | 443, 5656 → 443 |
| Block Handler | block-handler | node:20-alpine | Internal: 3000 |

---

## 🧪 Testing

### From Local Machine (Server)

```bash
# Test on port 443
curl -k https://localhost:443

# Test on port 5656
curl -k https://localhost:5656

# Both should return the block page
```

### From Internet (Any Client)

```bash
# Test from external client
curl -k https://173.167.175.162

# With specific hostname for DNS sinkhole testing
curl -k -H "Host: malware-site.evil" https://173.167.175.162
```

### From Browser

**Without CA installed:**
- Visit: `https://173.167.175.162`
- Expected: `ERR_SSL_PROTOCOL_ERROR` or certificate warning
- Reason: Browser doesn't trust nskp.io CA

**After CA installed:**
- Visit: `https://173.167.175.162`
- Expected: Block page displays
- Lock icon may show "Not Secure" (IP address, not domain)

---

## 🎯 DNS Sinkhole Configuration

### How DNS Sinkholing Works

1. **Configure DNS** to resolve malicious domains to `173.167.175.162`
2. **User tries to access** `https://malware-site.evil`
3. **DNS resolves** to `173.167.175.162`
4. **Browser connects** to your Caddy server
5. **Caddy generates certificate** for `malware-site.evil` using nskp.io CA
6. **Block handler queries** Netskope API for domain category
7. **User sees** branded block page with category information

### Example DNS Configuration

For a DNS sinkhole, you would configure your DNS server (Pi-hole, BIND, etc.) to resolve malicious domains to your IP:

```
# Example DNS zone entries
malware-site.evil.          A    173.167.175.162
phishing-site.bad.          A    173.167.175.162
suspicious-domain.com.      A    173.167.175.162
```

Or use wildcard DNS filtering with response policy zones (RPZ).

---

## 📊 System Status

### Check Container Status

```bash
docker compose ps
```

### View Logs

```bash
# All logs
docker compose logs -f

# Caddy only
docker compose logs -f caddy

# Block handler only
docker compose logs -f block-handler
```

### Restart Services

```bash
# Restart all
docker compose restart

# Restart specific service
docker compose restart caddy
docker compose restart block-handler
```

---

## 🔐 Security Summary

### ✅ Security Features Implemented

1. **XSS Protection** - HTML escaping on all user input
2. **Header Injection Protection** - Validates hostnames, blocks CRLF
3. **Credentials Secured** - Moved to `.env` file (git-ignored)
4. **Admin API Secured** - Not exposed to internet, localhost only
5. **Information Disclosure Reduced** - Minimal logging
6. **Security Headers** - X-Content-Type-Options, X-Frame-Options

### ⚠️ Security Considerations

1. **CA Private Key Security**
   - Location: `/home/tco/caddy-deploy/data/caddy/pki/authorities/nskp/root.key`
   - **Critical:** Protect this file - anyone with access can sign certificates clients will trust
   - Recommend: `chmod 600` and secure backups

2. **Credentials Rotation Required**
   - The API credentials in `.env` were previously exposed in git
   - **Action Required:** Rotate Netskope API credentials
   - See: [SECURITY-FIXES.md](SECURITY-FIXES.md)

3. **Firewall Configuration**
   - Only port 443 should be exposed to internet
   - Port 5656 is optional for local testing
   - Port 2019 (admin) should NOT be exposed

---

## 📁 File Structure

```
/home/tco/caddy-deploy/
├── caddy_config/
│   └── Caddyfile                    # Main Caddy configuration
├── block-handler/
│   ├── server.js                    # Node.js block page handler
│   ├── blocked.html                 # Block page template
│   └── netskope-logo.png           # Netskope branding
├── data/
│   └── caddy/
│       ├── pki/authorities/nskp/   # CA certificates & keys
│       └── certificates/           # Generated site certificates
├── docker-compose.yml              # Container orchestration
├── .env                            # API credentials (SECRET)
├── .env.example                    # Template for .env
├── .gitignore                      # Prevents credential leaks
├── nskp-io-root-ca.crt            # Root CA (for distribution)
├── INSTALL-CA-CERTIFICATE.md      # Client installation guide
├── SECURITY-FIXES.md              # Security audit & fixes
└── DEPLOYMENT-INFO.md             # This file
```

---

## 🚀 Quick Commands Reference

```bash
# Start services
docker compose up -d

# Stop services
docker compose down

# View logs
docker compose logs -f

# Restart
docker compose restart

# Check status
docker compose ps

# Test locally
curl -k https://localhost:443

# Test externally (from another machine)
curl -k https://173.167.175.162

# Export CA certificate
docker compose exec caddy cat /data/caddy/pki/authorities/nskp/root.crt > nskp-io-root-ca.crt

# Check generated certificates
docker compose exec caddy ls -la /data/caddy/certificates/nskp/
```

---

## 📞 Troubleshooting

### Issue: ERR_SSL_PROTOCOL_ERROR in browser

**Solution:** Install the root CA certificate on the client
**Guide:** [INSTALL-CA-CERTIFICATE.md](INSTALL-CA-CERTIFICATE.md)

### Issue: Connection refused

**Check:**
```bash
# Is Caddy running?
docker compose ps

# Is port 443 listening?
netstat -tlnp | grep 443

# Check firewall
sudo ufw status
sudo iptables -L -n | grep 443
```

### Issue: Block page not showing

**Check:**
```bash
# View logs
docker compose logs block-handler

# Test block handler directly
docker compose exec caddy curl http://block-handler:3000

# Verify API credentials
docker compose exec block-handler sh -c 'echo $API_TOKEN'
```

### Issue: Certificates not being generated

**Check:**
```bash
# View Caddy logs
docker compose logs caddy

# Check admin endpoint is accessible
docker compose exec caddy curl http://localhost:2019/allowed

# Manually trigger certificate generation
curl -k https://173.167.175.162
```

---

## 📈 Monitoring

### Important Metrics to Monitor

1. **Certificate generation rate** - Unusual spikes may indicate attack
2. **API call volume** - Monitor Netskope API usage
3. **Failed requests** - Check logs for errors
4. **Disk space** - Certificates are stored on disk
5. **Memory usage** - Node.js process in block-handler

### Log Locations

- **Caddy logs:** `docker compose logs caddy`
- **Block handler logs:** `docker compose logs block-handler`
- **Container logs:** `/var/lib/docker/containers/`

---

## 🔄 Backup & Recovery

### What to Backup

1. **CA Private Key (Critical):**
   ```bash
   tar -czf nskp-ca-backup-$(date +%Y%m%d).tar.gz data/caddy/pki/authorities/nskp/
   ```

2. **Configuration:**
   ```bash
   tar -czf config-backup-$(date +%Y%m%d).tar.gz caddy_config/ block-handler/ docker-compose.yml .env
   ```

3. **Generated Certificates (Optional):**
   ```bash
   tar -czf certs-backup-$(date +%Y%m%d).tar.gz data/caddy/certificates/
   ```

### Recovery

```bash
# Restore CA
tar -xzf nskp-ca-backup-YYYYMMDD.tar.gz

# Restart services
docker compose restart
```

---

## 📚 Documentation Index

- **[README.md](README.md)** - Project overview and main documentation
- **[INSTALL-CA-CERTIFICATE.md](INSTALL-CA-CERTIFICATE.md)** - Client certificate installation guide
- **[SECURITY-FIXES.md](SECURITY-FIXES.md)** - Security audit and implemented fixes
- **[DEPLOYMENT-INFO.md](DEPLOYMENT-INFO.md)** - This file
- **[START-HERE.md](START-HERE.md)** - Quick start guide

---

**Deployment Version:** 1.0
**Last Updated:** 2025-12-15
**Public IP:** 173.167.175.162
**CA:** nskp.io
**Status:** ✅ Production Ready (after credential rotation)

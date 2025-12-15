# Security Fixes Applied

## Summary

This document details the Priority 1 security vulnerabilities that have been fixed in this deployment.

**⚠️ Important:** This deployment is designed for **DNS sinkholing** - malicious domains are resolved to this server's IP address. Therefore, hostname validation is adjusted to accept ANY hostname (including localhost and private IPs) while still protecting against injection attacks.

## Fixed Vulnerabilities

### 1. ✅ Cross-Site Scripting (XSS) - HIGH SEVERITY

**Status:** FIXED

**Changes Made:**
- Added `escapeHtml()` function in [block-handler/server.js:10-20](block-handler/server.js#L10-L20)
- All user-controlled input is now HTML-escaped before rendering:
  - URL values are escaped at line 124
  - Category values are escaped at line 125
- Added security headers to responses:
  - `X-Content-Type-Options: nosniff`
  - `X-Frame-Options: DENY`

**Testing:**
```bash
# XSS attacks are now blocked
curl -k "https://localhost:5656/<script>alert('xss')</script>"
# Result: Script tags are URL-encoded and HTML-escaped

curl -k "https://localhost:5656/<img src=x onerror=alert(1)>"
# Result: Payload is escaped and not executable
```

---

### 2. ✅ Header Injection Attacks - MEDIUM SEVERITY

**Status:** FIXED (Adjusted for DNS Sinkhole Use Case)

**Changes Made:**
- Added `isValidHostname()` function in [block-handler/server.js:22-48](block-handler/server.js#L22-L48)
- Validates hostname exists and prevents injection attacks
- **For DNS sinkholing:** Accepts ANY valid hostname including:
  - localhost
  - Private IP addresses (10.x, 192.168.x, 172.x)
  - Public domain names
  - IPv4 and IPv6 addresses
- Blocks malicious input:
  - Control characters (\x00-\x1F, \x7F)
  - Header injection characters (\r, \n)
  - Script injection characters (<, >, ', ", \)
  - Hostnames over 253 characters

**Why This Approach:**
This is a DNS sinkhole - malicious domains get resolved to this server. We MUST accept any hostname, but we still protect against injection attacks by blocking dangerous characters.

**Testing:**
```bash
# DNS sinkhole accepts all domains
curl -k https://localhost:5656
# Result: ✅ Works (localhost accepted)

curl -k -H "Host: 192.168.1.1" https://localhost:5656
# Result: ✅ Works (private IP accepted)

curl -k -H "Host: malware-site.evil" https://localhost:5656
# Result: ✅ Works (any domain accepted)

# But injection attacks are blocked
curl -k -H $'Host: evil.com\r\nX-Injected: malicious' https://localhost:5656
# Result: ✅ Blocked (CRLF injection prevented)
```

---

### 3. ✅ Hardcoded Credentials - HIGH SEVERITY

**Status:** FIXED

**Changes Made:**
- Removed hardcoded API_TOKEN from [docker-compose.yml](docker-compose.yml)
- Created [.env](.env) file for credentials (git-ignored)
- Created [.env.example](.env.example) as template
- Created [.gitignore](.gitignore) to prevent credential leaks
- Updated docker-compose.yml to use `env_file` directive

**Configuration:**
```yaml
# Before (INSECURE):
environment:
  - API_TOKEN=cmJhY3YzOm5haWthRzRDcnlySTg2dnIwZnNqMg==

# After (SECURE):
env_file:
  - .env
```

**⚠️ ACTION REQUIRED:**
The previously exposed credentials should be rotated immediately:
1. Generate new API credentials in Netskope
2. Update `.env` file with new credentials
3. Restart services: `docker compose restart`

---

### 4. ✅ Insecure Admin API Endpoint - HIGH SEVERITY

**Status:** FIXED

**Changes Made:**
- Changed admin endpoint from `:2019` to `localhost:2019` in [Caddyfile:42](caddy_config/Caddyfile#L42)
- Removed port 2019 from exposed ports in [docker-compose.yml:21-22](docker-compose.yml#L21-L22)
- Admin API now only accessible from within container network

**Testing:**
```bash
# External access is blocked
curl http://localhost:2019/allowed
# Result: Connection refused

# Access from within container still works
docker compose exec caddy curl http://localhost:2019/allowed
# Result: 200 OK
```

---

### 5. ✅ Host Header Validation - MEDIUM SEVERITY

**Status:** FIXED (Adapted for DNS Sinkhole)

**Changes Made:**
- Added Host header existence check in [block-handler/server.js:93-98](block-handler/server.js#L93-L98)
- Returns 400 Bad Request if Host header is missing
- Returns 400 Bad Request if hostname contains injection characters
- **Important:** Does NOT reject localhost/private IPs (required for DNS sinkholing)

**Testing:**
```bash
# Missing Host header is rejected
curl -k https://localhost:5656 -H "Host:"
# Result: Bad Request: Missing Host header

# Valid domains work (including private IPs for DNS sinkhole)
curl -k https://localhost:5656
# Result: ✅ Block page displays
```

---

### 6. ✅ Information Disclosure - MEDIUM SEVERITY

**Status:** FIXED

**Changes Made:**
- Removed verbose API response logging from [block-handler/server.js:82-98](block-handler/server.js#L82-L98)
- Removed request header logging
- Only essential errors are logged
- API tokens no longer appear in logs

**Before:**
```javascript
console.log('API Response Headers:', JSON.stringify(res.headers, null, 2));
console.log('API Response Body:', data);
console.log('Request Headers:', JSON.stringify(req.headers, null, 2));
```

**After:**
```javascript
console.log('Request for hostname:', hostname);
console.error('Error querying API:', error.message);
```

---

## DNS Sinkhole Security Model

### What is DNS Sinkholing?

DNS sinkholing redirects malicious domain names to a controlled server (this Caddy deployment). When users try to access malware/phishing sites, DNS resolves those domains to this server's IP, which then:

1. Accepts the connection for ANY hostname
2. Queries Netskope API for the domain's category
3. Displays a block page explaining why it was blocked

### Security Considerations for DNS Sinkholing

**Why we accept localhost/private IPs:**
- Malicious domains can have ANY name, including look-alikes of localhost
- Some malware uses IP addresses directly
- DNS sinkhole must accept everything to be effective

**How we stay secure:**
- ✅ XSS protection via HTML escaping (all output is safe)
- ✅ Header injection protection (blocks \r, \n, control chars)
- ✅ No SSRF risk (we don't make requests to user-supplied hosts)
- ✅ Credentials protected (moved to .env)
- ✅ Admin API secured (not exposed)

**What we validate:**
- ❌ Not rejected: localhost, private IPs, any domain name
- ✅ Rejected: Missing Host header
- ✅ Rejected: Control characters in hostname
- ✅ Rejected: CRLF injection attempts (\r\n)
- ✅ Rejected: XSS characters in hostname (<, >, ', ")
- ✅ Rejected: Hostnames over 253 chars

---

## Security Test Results

All Priority 1 vulnerabilities have been tested and confirmed fixed:

| Test | Result | Status |
|------|--------|--------|
| XSS in URL | Properly escaped | ✅ PASS |
| XSS in category | Properly escaped | ✅ PASS |
| Header injection (CRLF) | Blocked | ✅ PASS |
| Missing Host header | Rejected | ✅ PASS |
| Admin port exposed | Not accessible | ✅ PASS |
| Credentials in code | Removed | ✅ PASS |
| Localhost requests | Working (DNS sinkhole) | ✅ PASS |
| Private IP requests | Working (DNS sinkhole) | ✅ PASS |
| Malicious domain names | Working (DNS sinkhole) | ✅ PASS |
| Valid public domains | Working normally | ✅ PASS |

---

## Configuration Files Changed

1. [block-handler/server.js](block-handler/server.js) - Added security functions and validation
2. [caddy_config/Caddyfile](caddy_config/Caddyfile) - Secured admin endpoint
3. [docker-compose.yml](docker-compose.yml) - Removed exposed port and hardcoded credentials
4. [.env](.env) - Created for credential storage (git-ignored)
5. [.env.example](.env.example) - Created as template
6. [.gitignore](.gitignore) - Created to prevent credential leaks

---

## Remaining Recommendations

While Priority 1 issues are fixed, consider these Priority 2 enhancements:

1. **Add Content-Security-Policy header** - Additional XSS defense-in-depth
2. **Implement rate limiting** - Prevent DoS attacks
3. **Add HSTS header** - Force HTTPS for all connections
4. **Set up monitoring** - Detect suspicious activity
5. **Regular security audits** - Keep dependencies updated

---

## Credential Rotation

**IMPORTANT:** The API credentials that were previously hardcoded in docker-compose.yml should be considered compromised if this file was ever committed to version control or shared.

**Steps to rotate credentials:**

1. Log into Netskope admin console
2. Revoke the old API token: `cmJhY3YzOm5haWthRzRDcnlySTg2dnIwZnNqMg==`
3. Generate new API credentials
4. Update `.env` file with new credentials:
   ```bash
   API_TOKEN=your_new_base64_token
   ```
5. Restart services:
   ```bash
   docker compose restart block-handler
   ```

---

## Deployment Notes

After pulling these security fixes:

1. Ensure `.env` file exists with valid credentials
2. Never commit `.env` to version control
3. Restart all services: `docker compose down && docker compose up -d`
4. Verify services are running: `docker compose ps`
5. Test DNS sinkhole functionality:
   ```bash
   # Should work for any hostname
   curl -k https://localhost:5656
   curl -k -H "Host: malware-site.evil" https://localhost:5656
   curl -k -H "Host: 192.168.1.1" https://localhost:5656
   ```

---

## Security Contact

For security issues or questions:
- Review [SECURITY-FIXES.md](SECURITY-FIXES.md) (this file)
- Check logs: `docker compose logs -f`
- Report vulnerabilities responsibly

---

**Last Updated:** 2025-12-15
**Security Fixes Version:** 1.1 (DNS Sinkhole Optimized)
**Risk Level:** Medium (down from High after fixes)
**Use Case:** DNS Sinkhole for malicious domain blocking

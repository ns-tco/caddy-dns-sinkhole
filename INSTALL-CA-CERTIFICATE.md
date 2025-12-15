# Install nskp.io Root CA Certificate

## Why You're Seeing ERR_SSL_PROTOCOL_ERROR

Your browser doesn't trust the `nskp.io` certificate authority that Caddy is using to sign certificates. You need to install the root CA certificate to fix this.

## Root Certificate Location

The root certificate has been exported to:
```
/home/tco/caddy-deploy/nskp-io-root-ca.crt
```

**Certificate Details:**
- **Subject:** CN=nskp.io Root CA
- **Issuer:** CN=nskp.io Root CA (self-signed)
- **Valid:** 2025-12-15 to 2035-10-24 (10 years)

---

## Installation Instructions by Platform

### 🪟 Windows

#### Method 1: Using Certificate Manager (Recommended)

1. **Open Certificate File:**
   - Double-click `nskp-io-root-ca.crt`
   - Or right-click → Install Certificate

2. **Certificate Import Wizard:**
   - Store Location: **Local Machine** (requires admin) or **Current User**
   - Click **Next**

3. **Certificate Store:**
   - Select: **Place all certificates in the following store**
   - Click **Browse**
   - Select: **Trusted Root Certification Authorities**
   - Click **OK**

4. **Complete:**
   - Click **Next** → **Finish**
   - Click **Yes** on security warning

5. **Restart Browser**

#### Method 2: Using Command Line (Admin)

```powershell
certutil -addstore -user Root nskp-io-root-ca.crt
```

---

### 🍎 macOS

#### Method 1: Using Keychain Access (Recommended)

1. **Import Certificate:**
   - Double-click `nskp-io-root-ca.crt`
   - Or: Keychain Access → File → Import Items

2. **Select Keychain:**
   - Choose: **login** or **System** (System requires admin)
   - Click **Add**

3. **Trust Certificate:**
   - In Keychain Access, search for: **nskp.io Root CA**
   - Double-click the certificate
   - Expand **Trust** section
   - Set "When using this certificate" to: **Always Trust**
   - Close and enter password

4. **Restart Browser**

#### Method 2: Using Command Line

```bash
sudo security add-trusted-cert -d -r trustRoot -k /Library/Keychains/System.keychain nskp-io-root-ca.crt
```

---

### 🐧 Linux

#### Ubuntu / Debian

```bash
# Copy certificate to trusted store
sudo cp nskp-io-root-ca.crt /usr/local/share/ca-certificates/nskp-io-root-ca.crt

# Update CA certificates
sudo update-ca-certificates

# Restart browser
```

#### Fedora / RHEL / CentOS

```bash
# Copy certificate to trusted store
sudo cp nskp-io-root-ca.crt /etc/pki/ca-trust/source/anchors/

# Update CA trust
sudo update-ca-trust

# Restart browser
```

#### Arch Linux

```bash
# Copy certificate to trusted store
sudo cp nskp-io-root-ca.crt /etc/ca-certificates/trust-source/anchors/

# Update CA certificates
sudo trust extract-compat

# Restart browser
```

---

### 🌐 Browser-Specific Instructions

Some browsers use their own certificate stores instead of the system's.

#### Google Chrome (All Platforms)

1. **Open Settings:** `chrome://settings/certificates`
2. **Navigate to:** Authorities tab
3. **Click:** Import
4. **Select:** `nskp-io-root-ca.crt`
5. **Check:** "Trust this certificate for identifying websites"
6. **Click:** OK
7. **Restart Chrome**

#### Mozilla Firefox (All Platforms)

1. **Open Settings:** `about:preferences#privacy`
2. **Scroll to:** Certificates section
3. **Click:** View Certificates
4. **Navigate to:** Authorities tab
5. **Click:** Import
6. **Select:** `nskp-io-root-ca.crt`
7. **Check:** "Trust this CA to identify websites"
8. **Click:** OK
9. **Restart Firefox**

#### Microsoft Edge

Edge uses the Windows certificate store on Windows and the system store on other platforms. Follow the OS-specific instructions above.

#### Safari

Safari uses the macOS Keychain. Follow the macOS instructions above.

---

## Verification

After installing the certificate:

1. **Restart your browser completely** (close all windows)

2. **Visit:** `https://localhost:5656`

3. **Expected Result:**
   - ✅ No SSL error
   - ✅ Lock icon in address bar (might say "Not Secure" due to localhost)
   - ✅ Block page displays

4. **Check Certificate:**
   - Click lock icon → Certificate
   - Should show:
     - **Issued to:** localhost (or the domain you're testing)
     - **Issued by:** nskp.io Intermediate CA
     - **Root CA:** nskp.io Root CA

---

## Testing from Command Line

```bash
# Should work without -k flag now
curl https://localhost:5656

# Or with certificate verification
curl --cacert nskp-io-root-ca.crt https://localhost:5656
```

---

## Troubleshooting

### Still seeing ERR_SSL_PROTOCOL_ERROR?

1. **Clear browser cache:**
   - Chrome: `chrome://settings/clearBrowserData`
   - Firefox: `about:preferences#privacy` → Clear Data
   - Check "Cached images and files" and "Cookies"

2. **Restart browser completely:**
   - Close ALL browser windows
   - Kill background processes
   - Re-open browser

3. **Check certificate is installed:**
   - Windows: `certmgr.msc` → Trusted Root Certification Authorities → Certificates
   - macOS: Keychain Access → Certificates
   - Linux: `ls /etc/ssl/certs/ | grep nskp`

4. **Verify Caddy is running:**
   ```bash
   docker compose ps
   docker compose logs caddy --tail 20
   ```

5. **Test with curl:**
   ```bash
   curl -v https://localhost:5656 2>&1 | grep -i verify
   ```

### Certificate Already Exists Error?

If you see "certificate already exists":
- Windows: Delete old certificate from Certificate Manager first
- macOS: Delete old certificate from Keychain Access first
- Linux: Remove old certificate from `/usr/local/share/ca-certificates/` first

### Still Having Issues?

Try accessing with a specific hostname instead of localhost:

```bash
# Add to /etc/hosts (or C:\Windows\System32\drivers\etc\hosts)
127.0.0.1 test.local

# Then access
https://test.local:5656
```

---

## Security Notes

### Is This Safe?

Installing this root CA means:
- ✅ You trust certificates signed by this CA
- ⚠️ Anyone with access to `/data/caddy/pki/authorities/nskp/root.key` can sign certificates you'll trust
- 🔒 This is intended for **development/testing/DNS sinkhole** environments

### For Production DNS Sinkhole:

1. **Protect the root key:**
   ```bash
   chmod 600 /home/tco/caddy-deploy/data/caddy/pki/authorities/nskp/root.key
   ```

2. **Backup the CA:**
   ```bash
   tar -czf nskp-ca-backup.tar.gz data/caddy/pki/authorities/nskp/
   ```

3. **Distribute certificate to all clients:**
   - Use Group Policy (Windows)
   - Use MDM (macOS/iOS)
   - Use configuration management (Linux)

### Removing the Certificate

If you need to remove trust later:

- **Windows:** `certmgr.msc` → Find → Delete
- **macOS:** Keychain Access → Find → Delete
- **Linux:** `sudo rm /usr/local/share/ca-certificates/nskp-io-root-ca.crt && sudo update-ca-certificates`

---

## Quick Reference

| Platform | Command |
|----------|---------|
| Windows (Admin) | `certutil -addstore -user Root nskp-io-root-ca.crt` |
| macOS (Admin) | `sudo security add-trusted-cert -d -r trustRoot -k /Library/Keychains/System.keychain nskp-io-root-ca.crt` |
| Ubuntu/Debian | `sudo cp nskp-io-root-ca.crt /usr/local/share/ca-certificates/ && sudo update-ca-certificates` |
| Fedora/RHEL | `sudo cp nskp-io-root-ca.crt /etc/pki/ca-trust/source/anchors/ && sudo update-ca-trust` |
| Chrome | `chrome://settings/certificates` → Authorities → Import |
| Firefox | `about:preferences#privacy` → Certificates → Authorities → Import |

---

**Need Help?** Check [SECURITY-FIXES.md](SECURITY-FIXES.md) or [README.md](README.md)

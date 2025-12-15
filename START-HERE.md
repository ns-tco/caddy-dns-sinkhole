# 👋 START HERE - Caddy Proxy Deployment

Welcome to the Caddy Reverse Proxy deployment package! This document will help you get started quickly.

## 📚 Which Document Should I Read?

Choose based on your situation:

### 🏃 Just Want to Deploy Fast?
**→ Read: QUICKSTART-SIMPLE.md**
- 2-minute deployment guide
- Zero configuration needed
- Get running immediately

### 📖 Want Complete Documentation?
**→ Read: README.md**
- Full technical documentation
- Architecture details
- Comprehensive troubleshooting
- All configuration options

### 🔖 Need Quick Reference?
**→ Read: QUICK-REFERENCE.md**
- One-page reference card
- Essential commands
- Common troubleshooting
- Quick solutions

---

## 🚀 Absolute Fastest Way to Deploy

If you just want to get this running NOW:

1. Extract files:
   ```bash
   tar -xzf caddy-deploy-SIMPLE.tar.gz
   cd caddy-deploy
   ```

2. Deploy:
   ```bash
   docker-compose up -d
   ```

3. Test:
   ```bash
   curl -k https://localhost:5656
   ```

Done! (No configuration needed)

---

## 📦 What's in This Package?

### Core Application
- `docker-compose.yml` - Orchestration configuration
- `caddy_config/Caddyfile` - Reverse proxy rules
- `block-handler/` - API handler and block page
- `deploy.sh` - Automated deployment script

### Documentation
- `START-HERE.md` - This file
- `QUICKSTART-SIMPLE.md` - Fast deployment
- `SIMPLIFIED-DEPLOYMENT.md` - Complete simple guide
- `README.md` - Complete docs
- `QUICK-REFERENCE.md` - Command reference
- `SSH-DEPLOYMENT.md` - SSH deployment guide

### Runtime Directories
- `data/` - Caddy runtime data & certificates
- `config/` - Caddy configuration storage
- `certs/` - Certificate files
- `ca/` - Certificate authority
- `www/` - Static content

---

## ⚙️ What This Does

This is a **reverse proxy** that:

1. ✅ Intercepts HTTPS traffic on port 5656
2. ✅ Generates SSL certificates on-demand
3. ✅ Queries Netskope API for URL categories
4. ✅ Shows branded block page with category info

**Use Case**: Web filtering and URL categorization with branded block pages.

---

## 🔧 What You CAN Configure (Optional)

Only 1 thing is configurable:

### API Credentials
Edit `docker-compose.yml` lines 39-40:
```yaml
- API_URL=https://your-instance.goskope.com/api/v2/nsiq/urllookup
- API_TOKEN=your_base64_encoded_token
```

Everything else works with defaults!

---

## 🆘 Quick Help

### "Services won't start"
→ Check logs: `docker-compose logs`

### "How do I test it?"
→ Run: `curl -k https://localhost:5656`

### "Can I customize the block page?"
→ Yes! Edit `block-handler/blocked.html`

### "Where are full instructions?"
→ See README.md

---

## 📞 Support Path

1. **First**: Check QUICK-REFERENCE.md for common issues
2. **Second**: Read README.md troubleshooting section
3. **Third**: Check logs with `docker-compose logs -f`

---

## 🎯 Recommended Reading Order

For first-time deployers:

1. **START-HERE.md** (this file) - 2 min
2. **QUICKSTART-SIMPLE.md** - 2 min
3. Deploy and test!
4. If issues: **README.md** troubleshooting

For experienced users:

1. **QUICK-REFERENCE.md** - 1 min
2. `docker-compose up -d`

For production deployments:

1. **SIMPLIFIED-DEPLOYMENT.md** - Complete guide
2. **README.md** - Read security and customization sections
3. **QUICK-REFERENCE.md** - Keep handy for operations

---

## 🔥 TL;DR - Absolute Minimum

```bash
# 1. Extract
tar -xzf caddy-deploy-SIMPLE.tar.gz && cd caddy-deploy

# 2. (Optional) Edit API credentials in docker-compose.yml

# 3. Deploy
docker-compose up -d

# 4. Test
curl -k https://localhost:5656
```

That's it! 🎉

---

## 📖 Full Documentation Map

```
START-HERE.md                  ← You are here
    ↓
QUICKSTART-SIMPLE.md          ← Fast deployment (2 min)
    ↓
[Deploy & Test]
    ↓
QUICK-REFERENCE.md            ← Daily operations
    ↓
README.md                     ← Deep dive when needed
    ↓
SIMPLIFIED-DEPLOYMENT.md      ← Complete simple guide
SSH-DEPLOYMENT.md             ← SSH deployment
```

---

## ✅ Ready to Start?

**New users**: Open **QUICKSTART-SIMPLE.md** next

**Experienced users**: Open **QUICK-REFERENCE.md** next

**Want full docs**: Open **README.md** next

---

## 🌐 Access Your Deployment

After deploying:
- **Same machine:** `https://localhost:5656`
- **Other machines:** `https://your-host-ip:5656`
- **Browser:** Navigate to `https://192.168.1.100:5656` (use your IP)

---

**Questions?** All documentation is in this package. Start with QUICKSTART-SIMPLE.md!

Good luck! 🚀

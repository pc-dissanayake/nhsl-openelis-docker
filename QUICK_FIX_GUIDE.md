# 🚀 OpenELIS Backend Fix - Quick Start Guide

## The Problem
Frontend showing "User not authenticated, not getting menu" and "Failed to fetch" errors

## The Root Cause
✗ Missing CORS headers in nginx proxy  
✗ Backend not trusting X-Forwarded headers  
✗ API endpoints unreachable from frontend

---

## 🟢 ONE-COMMAND FIX

```bash
cd /home/openelis/openelis-docker && bash deploy-fixes.sh
```

**This will:**
- ✓ Backup original configs
- ✓ Deploy CORS-enabled nginx
- ✓ Configure backend for proxy headers
- ✓ Restart services
- ✓ Verify fixes

**Time to complete**: ~2-3 minutes

---

## ✅ Verify It Works

```bash
# Option 1: Run diagnostics
bash /home/openelis/openelis-docker/diagnostics.sh

# Option 2: Manual test
curl -X OPTIONS http://10.51.44.100/api/

# Option 3: Test in browser
1. Open http://10.51.44.100/
2. Press Ctrl+Shift+R
3. Open DevTools (F12)
4. Check Console - should show NO "Failed to fetch"
5. Login with admin / adminADMIN!
```

---

## 📋 What Was Fixed

| Issue | File | Fix |
|-------|------|-----|
| Missing CORS headers | `nginx.conf` | Added Access-Control-Allow-* headers |
| Proxy header handling | `SystemConfiguration.properties` | Enabled RemoteIp valve config |
| SSL verification | `nginx.conf` | Disabled cert verification for self-signed |
| Cookie handling | `nginx.conf` | Configured Set-Cookie forwarding |
| Session timeout | `SystemConfiguration.properties` | Set 30-minute timeout |

---

## 📁 Files Modified

```
✓ configs/nginx/nginx.conf
✓ configs/properties/SystemConfiguration.properties  
✓ configs/nginx/nginx.conf.fixed (reference)
```

Backups saved to: `configs/backups/<timestamp>/`

---

## 🔧 Manual Fix Alternative

If automated script fails:

```bash
# 1. Update nginx
cp /home/openelis/openelis-docker/configs/nginx/nginx.conf.fixed \
   /home/openelis/openelis-docker/configs/nginx/nginx.conf
docker exec openelisglobal-proxy nginx -s reload

# 2. Restart backend
docker restart openelisglobal-webapp

# 3. Wait for restart
sleep 10

# 4. Clear browser cache
# Press Ctrl+Shift+R on http://10.51.44.100/
```

---

## 🔍 Troubleshooting

### Still seeing "Failed to fetch"?
```bash
# Check nginx reloaded
docker exec openelisglobal-proxy grep "Access-Control" /etc/nginx/nginx.conf

# Check logs
docker logs openelisglobal-proxy | tail -20
docker logs openelisglobal-webapp | tail -20

# Restart proxy
docker restart openelisglobal-proxy
```

### Login failing?
```bash
# Check backend is running
docker ps | grep openelisglobal-webapp

# Check credentials (default)
# Username: admin
# Password: adminADMIN!

# View auth logs
docker logs openelisglobal-webapp | grep -i auth
```

### CORS still not working?
```bash
# Verify CORS headers returned
curl -i -X OPTIONS http://10.51.44.100/api/

# Should see:
# Access-Control-Allow-Origin: *
# Access-Control-Allow-Methods: GET, POST, PUT, DELETE, OPTIONS...
```

---

## 📚 Documentation

| Document | Purpose |
|----------|---------|
| `FIX_COMPLETE_GUIDE.md` | Full technical details |
| `HAR_ANALYSIS_REPORT.md` | Network analysis findings |
| `BACKEND_CONFIG_FIXES.md` | Backend configuration details |
| `deploy-fixes.sh` | Automated deployment script |
| `diagnostics.sh` | Diagnostic verification script |

---

## ✅ Success Criteria

After fix, you should see:

✓ http://10.51.44.100/ loads without errors  
✓ Console has NO "Failed to fetch" messages  
✓ Menu appears in header  
✓ Can login with admin / adminADMIN!  
✓ Can navigate and use the application  
✓ No "User not authenticated" errors  
✓ Network requests show 200/201/204 status  

---

## 🆘 Still Having Issues?

1. **Run diagnostics**: `bash diagnostics.sh`
2. **Check logs**: `docker logs openelisglobal-proxy`
3. **Review full guide**: See `FIX_COMPLETE_GUIDE.md`
4. **Rollback if needed**: [See rollback section in full guide]

---

**Status**: ✅ READY TO DEPLOY  
**Updated**: February 12, 2026

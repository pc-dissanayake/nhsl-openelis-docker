# OpenELIS Backend Configuration - Complete Fix Guide

## 📊 Issues Analyzed

Based on the HAR file capture and console logs, we identified:

### Root Causes Identified
1. **Missing CORS Headers** - nginx proxy doesn't return Access-Control-Allow-* headers
2. **Improper X-Forwarded Header Handling** - Backend not configured to trust proxy headers  
3. **Authentication Endpoint Unreachable** - "Failed to fetch" errors from frontend
4. **SSL/TLS Configuration** - Self-signed certificate verification issues
5. **Session Management** - Session cookies not being properly transmitted

### Evidence from Logs
```
TypeError: Failed to fetch
Headers.js:87 User not authenticated, not getting menu
Utils.js:31 TypeError: Failed to fetch
SlideOverNotifications.jsx:58 Error checking subscription status: Failed to fetch Subscription data
```

These errors indicate:
- Browser cannot reach the API endpoints at all
- CORS policy is blocking requests
- Network error (not HTTP error), so proxy issue

---

## 🔧 Fixes Applied

### Fix #1: CORS Configuration in nginx
**File**: `/home/openelis/openelis-docker/configs/nginx/nginx.conf`

**Changes**:
- Added handling for CORS preflight (OPTIONS) requests
- Returns HTTP 204 No Content for preflight requests
- Added `Access-Control-Allow-*` headers to all API responses
- Set `Access-Control-Max-Age: 1728000` for credential caching
- Configured proper header exposure with `Access-Control-Expose-Headers`

**Key sections added**:
```nginx
location /api/ {
    # Handle CORS preflight requests
    if ($request_method = 'OPTIONS') {
        add_header 'Access-Control-Allow-Origin' '*' always;
        add_header 'Access-Control-Allow-Methods' 'GET, POST, PUT, DELETE, OPTIONS, PATCH, HEAD' always;
        add_header 'Access-Control-Allow-Headers' 'Authorization, DNT, X-CustomHeader, Keep-Alive, User-Agent, X-Requested-With, If-Modified-Since, Cache-Control, Content-Type' always;
        add_header 'Access-Control-Max-Age' '1728000' always;
        return 204;
    }
    
    # Regular requests with CORS headers
    proxy_pass https://oe.openelis.org:8443/api/;
    add_header 'Access-Control-Allow-Origin' '*' always;
    add_header 'Access-Control-Allow-Methods' 'GET, POST, PUT, DELETE, OPTIONS, PATCH, HEAD' always;
}
```

### Fix #2: Backend X-Forwarded Header Support
**File**: `/home/openelis/openelis-docker/configs/properties/SystemConfiguration.properties`

**Changes**:
- Enabled Tomcat RemoteIp valve configuration
- Configured backend to trust X-Forwarded-For header
- Set protocol header handling for proper HTTPS detection
- Added session timeout configuration

**Key properties added**:
```properties
# Proxy Configuration
server.tomcat.remoteip.enabled=true
server.tomcat.remoteip.internal-proxies=.*
server.tomcat.remoteip.protocol-header=X-Forwarded-Proto
server.tomcat.remoteip.protocol-header-value=https
server.tomcat.remoteip.remote-ip-header=X-Forwarded-For

# Session Configuration  
server.servlet.session.cookie.http-only=true
server.servlet.session.timeout=30m
```

### Fix #3: SSL/TLS Configuration in nginx
**Changes**:
- Disabled SSL certificate verification for backend (self-signed)
- Enabled SSL session reuse for performance
- Configured proper timeout values

```nginx
proxy_ssl_verify off;
proxy_ssl_verify_depth 0;
proxy_ssl_session_reuse on;

# Timeouts
proxy_connect_timeout 60s;
proxy_send_timeout 60s;
proxy_read_timeout 60s;
```

### Fix #4: Cookie Handling
**Changes**:
- Configured nginx to properly forward Set-Cookie headers
- Set correct cookie path for API requests

```nginx
proxy_pass_header Set-Cookie;
proxy_cookie_path ~^/api/ "/api/";
```

---

## 📋 Deployment Instructions

### Option A: Automated Fix Deployment (Recommended)

```bash
cd /home/openelis/openelis-docker
bash deploy-fixes.sh
```

This script:
1. ✓ Backs up original configuration files
2. ✓ Deploys updated nginx.conf with CORS
3. ✓ Validates nginx configuration syntax
4. ✓ Reloads nginx
5. ✓ Adds backend properties
6. ✓ Restarts backend services
7. ✓ Verifies fixes

### Option B: Manual Deployment

**Step 1**: Update nginx configuration
```bash
cp /home/openelis/openelis-docker/configs/nginx/nginx.conf.fixed \
   /home/openelis/openelis-docker/configs/nginx/nginx.conf
```

**Step 2**: Validate configuration
```bash
docker exec openelisglobal-proxy nginx -t
```

**Step 3**: Reload nginx
```bash
docker exec openelisglobal-proxy nginx -s reload
```

**Step 4**: Add backend properties
```bash
# Append properties to SystemConfiguration.properties
# See Fix #2 above for exact content
```

**Step 5**: Restart backend
```bash
docker restart openelisglobal-webapp
sleep 10  # Wait for restart
```

---

## ✅ Post-Fix Verification

### 1. Check CORS Headers
```bash
curl -X OPTIONS \
  -H "Origin: http://localhost" \
  -H "Access-Control-Request-Method: POST" \
  -v http://10.51.44.100/api/
```

Expected response includes:
- `Access-Control-Allow-Origin: *`
- `Access-Control-Allow-Methods: GET, POST, PUT, DELETE, OPTIONS, PATCH, HEAD`
- HTTP Status: 204 No Content

### 2. Test Authentication
```bash
curl -X POST \
  -H "Content-Type: application/json" \
  -d '{"username":"admin","password":"adminADMIN!"}' \
  http://10.51.44.100/api/auth/login
```

Expected response:
```json
{"authenticated":true,"sessionId":"..."}
```

### 3. Browser Testing
1. Open http://10.51.44.100/
2. Press Ctrl+Shift+R (hard refresh)
3. Open Developer Tools (F12) → Network tab
4. Login with: admin / adminADMIN!
5. Verify:
   - No "Failed to fetch" errors in Console
   - API requests complete successfully
   - Status codes are 200/201/204, not 0 or error
   - Menu appears after login
   - Navigation works

### 4. Diagnostics Script
```bash
bash /home/openelis/openelis-docker/diagnostics.sh
```

This will verify:
- ✓ All containers are running
- ✓ API endpoints are reachable
- ✓ CORS is properly configured
- ✓ Authentication endpoint works
- ✓ X-Forwarded headers are processed

---

## 🔍 Troubleshooting

### Issue: "Failed to fetch" still appearing

**Check 1**: Verify nginx configuration loaded
```bash
docker exec openelisglobal-proxy grep "Access-Control" /etc/nginx/nginx.conf
```

**Check 2**: Check nginx error log
```bash
docker logs openelisglobal-proxy | tail -20
```

**Check 3**: Verify nginx is running
```bash
docker restart openelisglobal-proxy
sleep 5
```

### Issue: Authentication fails with 401

**Check**: Backend logs
```bash
docker logs openelisglobal-webapp | grep -i "auth\|permission\|401"
```

**Fix**: Verify user credentials are correct (default: admin / adminADMIN!)

### Issue: Session expires immediately

**Check**: Session timeout settings
```bash
docker exec openelisglobal-webapp grep "session.timeout" /var/lib/openelis-global/properties/SystemConfiguration.properties
```

**Fix**: Increase timeout value if needed (default: 30m = 1800 seconds)

### Issue: Mixed content warnings in HTTPS

**Note**: These are normal with self-signed certificates. Ensure browser is set to allow insecure content from localhost.

---

## 📁 Files Modified/Created

```
/home/openelis/openelis-docker/
├── configs/nginx/nginx.conf                    [MODIFIED - Added CORS]
├── configs/nginx/nginx.conf.fixed              [NEW - Reference copy]
├── configs/properties/SystemConfiguration.properties  [MODIFIED - Added proxy config]
├── diagnostics.sh                              [NEW - Verification script]
├── deploy-fixes.sh                             [NEW - Automated deployment]
├── HAR_ANALYSIS_REPORT.md                      [NEW - Technical analysis]
├── BACKEND_CONFIG_FIXES.md                     [NEW - Configuration details]
└── configs/backups/<timestamp>/                [NEW - Automatic backups]
    ├── nginx.conf.orig
```

---

## 🎯 Expected Outcomes

After applying these fixes:

✅ **Frontend loads without errors**
- No red X errors in Network tab
- No "Failed to fetch" in Console
- Page renders completely

✅ **Authentication works**
- Login page appears
- Can login with admin/adminADMIN!
- Session is established

✅ **Menu system functional**
- Menu appears in header
- Can navigate between sections
- No 401 unauthorized errors

✅ **API calls succeed**
- All network requests show 200/201/204 status
- CORS headers present in responses
- Response bodies contain expected data

✅ **Logging works**
- Can view and search logs
- Reports generate without errors
- Data persists across sessions

---

## 📞 Support & Documentation

**Internal Documentation**:
- [Backend Config Fixes](BACKEND_CONFIG_FIXES.md)
- [HAR Analysis Report](HAR_ANALYSIS_REPORT.md)
- [Branding Setup](BRANDING_SETUP.md)

**External Resources**:
- [OpenELIS Documentation](http://docs.openelis-global.org/)
- [OpenELIS GitHub](https://github.com/DIGI-UW/openelis-docker)
- [Nginx CORS Guide](http://enable-cors.org/)

---

## 🔄 Rollback Instructions

If you need to revert the changes:

```bash
# Restore original nginx config
cd /home/openelis/openelis-docker
BACKUP_DIR=$(ls -dt configs/backups/*/ | head -1)
cp $BACKUP_DIR/nginx.conf.orig configs/nginx/nginx.conf

# Reload nginx
docker exec openelisglobal-proxy nginx -s reload

# Restart backend
docker restart openelisglobal-webapp
```

---

**Last Updated**: February 12, 2026
**Status**: ✅ Complete - Ready for deployment

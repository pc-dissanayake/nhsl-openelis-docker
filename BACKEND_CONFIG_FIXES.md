# OpenELIS Backend Configuration Fixes

## Issue: Authentication and CORS Failures

The OpenELIS backend needs to be properly configured to:
1. Trust X-Forwarded-* headers from the nginx proxy
2. Handle CORS requests
3. Properly validate sessions

## Files to Update

### 1. SystemConfiguration.properties
Add the following properties to handle proxied requests:

```properties
# Proxy Configuration - IMPORTANT for forwarded requests
server.tomcat.remoteip.enabled=true
server.tomcat.remoteip.internal-proxies=.*
server.tomcat.remoteip.protocol-header=X-Forwarded-Proto
server.tomcat.remoteip.protocol-header-value=https
server.tomcat.remoteip.port-header=X-Forwarded-Port
server.tomcat.remoteip.remote-ip-header=X-Forwarded-For

# Session Configuration
server.servlet.session.cookie.http-only=true
server.servlet.session.cookie.secure=false
server.servlet.session.cookie.path=/
server.servlet.session.timeout=30m

# CORS Configuration
server.cors.allowed-origins=*
server.cors.allowed-methods=GET,POST,PUT,DELETE,OPTIONS,PATCH,HEAD
server.cors.allowed-headers=*
server.cors.max-age=1728000
server.cors.allow-credentials=true

# API Configuration
api.base.url=http://10.51.44.100/api/
api.cors.enabled=true

# Authentication
auth.session.validate.interval=60
auth.session.timeout=1800
```

### 2. server.xml (Tomcat Configuration)
The Valve configuration needs to be added for proper X-Forwarded header handling:

```xml
<Engine name="Catalina" defaultHost="localhost">
    <!-- RemoteIpValve helps with proxied requests -->
    <Valve className="org.apache.catalina.valves.RemoteIpValve"
        internalProxies=".*"
        remoteIpHeader="X-Forwarded-For"
        protocolHeader="X-Forwarded-Proto"
        protocolHeaderHttpsValue="https" />
    
    <!-- Rest of configuration... -->
</Engine>
```

## CORS Configuration Verification Checklist

- [ ] Nginx returns `Access-Control-Allow-*` headers on `/api/` endpoints
- [ ] Browser OPTIONS requests (preflight) return 204 No Content
- [ ] Backend doesn't return 401 auth errors for preflight requests
- [ ] Session cookies are being set correctly
- [ ] X-Forwarded-* headers are preserved through proxy chain

## Debugging Commands

```bash
# Test CORS preflight
curl -X OPTIONS \
  -H "Origin: http://10.51.44.100" \
  -H "Access-Control-Request-Method: POST" \
  -H "Access-Control-Request-Headers: Content-Type" \
  -v http://10.51.44.100/api/auth/login

# Test authentication endpoint
curl -X POST \
  -H "Content-Type: application/json" \
  -d '{"username":"admin","password":"adminADMIN!"}' \
  http://10.51.44.100/api/auth/login

# Check if backend is accessible through proxy
curl -v http://10.51.44.100/api/

# Check nginx error logs
docker logs openelisglobal-proxy | grep -i "error\|cors\|upstream"

# Check backend logs
docker logs openelisglobal-webapp | grep -i "remoteip\|cors\|proxy"
```

## Testing Authentication Flow

1. Open browser dev tools (F12)
2. Go to Network tab
3. Navigate to http://10.51.44.100/
4. Look for:
   - First request to `/api/auth/validate` or similar
   - Check Response headers for `Access-Control-Allow-Origin`
   - Check Response status (should be 200, not failed)
   - Check for `Set-Cookie` header in responses
5. Try to login with `admin` / `adminADMIN!`
6. Verify session is established

## Expected Behavior After Fixes

✅ Frontend loads without errors
✅ Browser console shows no "Failed to fetch" errors  
✅ Authentication returns `{"authenticated":true}`
✅ Menu data loads from `/api/` endpoints
✅ User can browse the application
✅ Session persists across page refreshes


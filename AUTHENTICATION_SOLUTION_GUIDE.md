# OpenELIS Authentication Solution Guide

## Executive Summary
**Status**: Nginx proxy and CORS are correctly configured ✅  
**Status**: Backend API authentication endpoints are missing ❌  
**Impact**: Frontend cannot authenticate users - all API calls fail with "TypeError: Failed to fetch"

---

## Root Cause Analysis

### What We Found
1. **Frontend Configuration** - Correctly expects:
   - API Base URL: `/api`
   - API Prefix: `/OpenELIS-Global`
   - So calls: `/api/OpenELIS-Global/auth/login` and `/api/OpenELIS-Global/auth/validate`

2. **Nginx Configuration** - Correctly proxies:
   - `/api/*` → `https://oe.openelis.org:8443/api/*`
   - CORS headers properly configured
   - Routing is correct

3. **Backend API Issue** - Missing endpoints:
   - `/api/OpenELIS-Global/auth/login` → **404 Not Found**
   - `/api/OpenELIS-Global/auth/validate` → **404 Not Found**
   - Verified via HTTP Basic Auth (gets past Spring Security to dispatcher)

### What Actually Exists on Backend
Available REST endpoints per Spring Security logs:
- `/rest/open-configuration-properties` ✅
- `/rest/site-branding/**` ✅
- `/pluginServlet/**` ✅
- `/health/**` ✅

Form-based endpoints (JSP):
- `/ChangePasswordLogin` ✅
- `/UpdateLoginChangePassword` ✅

Missing:
- `/auth/login` REST endpoint ❌
- `/auth/validate` REST endpoint

---

## Solution Options

### Option 1: Update Container Images (Recommended)
**The simplest fix if newer images are available**

Check if there are newer development images available that include the auth endpoints:

```bash
# Pull latest develop versions
docker pull itechuw/openelis-global-2:latest
docker pull itechuw/openelis-global-2-frontend:latest

# Update docker-compose.yml to use latest instead of develop
# Then rebuild:
docker-compose down
docker-compose up -d
```

**Considerations**:
- Check release notes for breaking changes
- Backup database before upgrading
- May require database migrations

---

### Option 2: Build Custom Backend with Auth Endpoints (Advanced)
**If you have access to OpenELIS source code**

The auth endpoints need to be added to the backend:

```java
// File: src/main/java/org/openelisglobal/auth/controller/rest/AuthRestController.java
@RestController
@RequestMapping("/auth")
public class AuthRestController {
    
    @PostMapping("/login")
    public ResponseEntity<AuthResponse> login(
        @RequestBody LoginRequest request, 
        HttpSession session) {
        // Authenticate using Spring Security
        // Set session attributes
        // Return user info
        return ResponseEntity.ok(new AuthResponse(user));
    }
    
    @PostMapping("/logout")
    public ResponseEntity<?> logout(HttpSession session) {
        session.invalidate();
        return ResponseEntity.ok().build();
    }
    
    @GetMapping("/validate")
    public ResponseEntity<UserInfo> validate(HttpSession session) {
        // Return current user if authenticated
        // Return 401 if not authenticated
        Object user = session.getAttribute("user");
        if (user != null) {
            return ResponseEntity.ok(new UserInfo(user));
        }
        return ResponseEntity.status(401).build();
    }
    
    @GetMapping("/user-info")
    public ResponseEntity<UserInfo> getUserInfo(HttpSession session) {
        // Return current authenticated user's info
        return ResponseEntity.ok(getCurrentUser(session));
    }
}
```

Steps:
1. Clone OpenELIS source: `git clone https://github.com/I-TECH-UW/OpenELIS-Global-2.git`
2. Create `/auth/controller/rest/AuthRestController.java` class
3. Rebuild: `mvn clean package`
4. Update docker-compose.yml to use your custom image
5. Restart containers

---

### Option 3: Frontend-Only Workaround (Temporary)
**Quick fix while permanent solution is being developed**

Modify `/home/openelis/openelis-docker/configs/branding/.env` to use existing JSP authentication:

```properties
# Use form-based authentication instead of REST API
REACT_APP_AUTH_METHOD=form
REACT_APP_USE_REST_API=false

# Keep these for non-auth API calls
REACT_APP_API_BASE_URL=/api
REACT_APP_API_PREFIX=/OpenELIS-Global

# Disable polling for auth validation during load
REACT_APP_SKIP_AUTH_AT_STARTUP=true
```

Then rebuild frontend (requires source code):
```bash
cd openelis-global-2-frontend
npm install
REACT_APP_AUTH_METHOD=form npm run build
docker build -t openelis-global-2-frontend:custom .
docker-compose down
docker-compose up -d
```

---

### Option 4: Nginx Mock Auth Endpoint (Workaround)
**Implement mock auth in nginx to satisfy frontend requests**

Add to nginx.conf:

```nginx
# Mock authentication endpoint for development
location = /api/OpenELIS-Global/auth/login {
    if ($request_method = 'OPTIONS') {
        add_header 'Access-Control-Allow-Origin' '*' always;
        add_header 'Access-Control-Allow-Methods' 'GET, POST, OPTIONS' always;
        return 204;
    }
    
    if ($request_method = 'POST') {
        # Parse JSON and extract credentials
        # For now, accept any credentials
        add_header 'Content-Type' 'application/json';
        add_header 'Access-Control-Allow-Origin' '*';
        
        # Set a dummy session cookie
        add_header 'Set-Cookie' 'JSESSIONID=mock_session';
        
        return 200 '{"user":"admin","id":"1","authenticated":true}';
    }
}

location = /api/OpenELIS-Global/auth/validate {
    if ($request_method = 'OPTIONS') {
        add_header 'Access-Control-Allow-Origin' '*' always;
        return 204;
    }
    
    if ($request_method = 'GET') {
        add_header 'Content-Type' 'application/json';
        add_header 'Access-Control-Allow-Origin' '*';
        return 200 '{"user":"admin","authenticated":true}';
    }
}
```

**Limitations**:
- Bypasses backend authentication
- Not secure for production
- Backend APIs will still fail (no real authorization)
- Only unblocks frontend UI

---

## Recommended Path Forward

### Immediate (1-2 hours)
1. ✅ Verify nginx proxy configuration (DONE)
2. ✅ Confirm CORS headers (DONE)
3. ✅ Identify missing backend endpoints (DONE)
4. Try Option 1 (updated container images)

### Short-term (1-2 days)
If Option 1 fails:
1. Check OpenELIS GitHub for known issues
2. Contact OpenELIS support about missing auth endpoints
3. Implement Option 4 as temporary workaround

### Long-term (1-2 weeks)
1. Build custom backend with Option 2
2. OR wait for updated container images from OpenELIS
3. Test end-to-end authentication flow
4. Deploy to production

---

## Testing Verification

After applying any solution, verify with:

```bash
# Test login endpoint  
curl -X POST http://10.51.44.100/api/OpenELIS-Global/auth/login \
  -H "Content-Type: application/json" \
  -d '{"username":"admin","password":"adminADMIN!"}'

# Should return:
# - 200 OK with user JSON + JSESSIONID cookie
# NOT 404 or 302 redirect

# Test with cookie
curl -X GET http://10.51.44.100/api/OpenELIS-Global/auth/validate \
  -H "Cookie: JSESSIONID=<cookie-from-login>"

# Should return:
# - 200 OK with authenticated user info
```

---

## Contacts & Resources

- **OpenELIS GitHub**: https://github.com/I-TECH-UW/OpenELIS-Global-2
- **OpenELIS Docker Images**: https://hub.docker.com/r/itechuw
- **OpenELIS Documentation**: https://github.com/I-TECH-UW/OpenELIS-Global-2/wiki

---

## Summary

Your infrastructure is **correctly configured** on the proxy and CORS side. The issue is a **version mismatch** between the frontend (which expects REST auth endpoints) and the backend (which doesn't provide them).

**Next step**: Attempt to use a newer version of the OpenELIS containers that includes the missing authentication endpoints.

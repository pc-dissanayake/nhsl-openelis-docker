# OpenELIS API Authentication Issue - Root Cause & Solution

## Problem Identified
The frontend React application is calling REST API endpoints that **do not exist** on the OpenELIS backend:
- `/api/OpenELIS-Global/auth/login` - **404 Not Found**
- `/api/OpenELIS-Global/auth/validate` - **404 Not Found**

### What the Backend Actually Exposes
According to Spring Security logs, only these endpoints are unsecured/exposed:
- `/pluginServlet/**`
- `/ChangePasswordLogin`
- `/UpdateLoginChangePassword`
- `/health/**`
- `/rest/open-configuration-properties`
- `/docs/UserManual`
- `/rest/site-branding/**`

## Root Cause
The frontend (itechuw/openelis-global-2-frontend:develop) and backend (itechuw/openelis-global-2:develop) are version-mismatched or the backend is missing a required module/feature for REST authentication.

The frontend expects:
- JSON-based REST API authentication at `/api/OpenELIS-Global/auth/login`
- Validation endpoint at `/api/OpenELIS-Global/auth/validate`

The backend provides:
- Form-based JSP authentication via `/ChangePasswordLogin` and `/UpdateLoginChangePassword`
- No REST auth endpoints

## Solutions

### Solution 1: Use Backend JSP Authentication (Simplest)
Configure the frontend to use the existing OpenELIS JSP-based authentication:

1. **New Frontend Configuration (/branding/.env)**
   ```
   REACT_APP_USE_FORM_AUTH=true
   REACT_APP_LOGIN_FORM_URL=/ChangePasswordLogin
   REACT_APP_API_BASE_URL=/api
   REACT_APP_API_PREFIX=/OpenELIS-Global
   ```

2. **Implement simpler auth in frontend** - Instead of calling non-existent API endpoints, use existing OpenELIS authentication that sets JSESSIONID cookie

### Solution 2: Implement Missing API Endpoints (Best Long-term)
Create REST auth endpoints in the backend by adding a new Spring controller:

File: `OpenELIS-Global/src/main/java/org/openelisglobal/auth/controller/rest/AuthRestController.java`

```java
@RestController
@RequestMapping("/auth")
public class AuthRestController {
    
    @PostMapping("/login")
    public ResponseEntity<?> login(@RequestBody LoginRequest request) {
        // Authenticate user
        // Return user info or token
        // Set JSESSIONID cookie
    }
    
    @GetMapping("/validate")
    public ResponseEntity<?> validate(HttpSession session) {
        // Check current session
        // Return user info if valid
        // Return 401 if invalid
    }
}
```

### Solution 3: Frontend-Only Fix - Add Authentication Bypass
Configure CORS and add session handling to allow frontend to work with existing system.

## Immediate Workaround
Until endpoints are implemented, the frontend can:

1. **Use existing JSESSIONID cookies** - The backend IS setting JSESSIONID cookies
2. **Make authenticated requests** - Once a session is established, requests include the JSESSIONID and will work

Current issue: Frontend can't establish session because login endpoint doesn't exist.

## Nginx Configuration (Already Applied)
The nginx proxy is correctly configured:
```nginx
location /api/ {
    proxy_pass https://oe.openelis.org:8443/api/;
}
```

Frontend configured to add `/OpenELIS-Global` prefix, so:
- Frontend request: `/api/OpenELIS-Global/auth/login`
- Becomes backend request: `/api/OpenELIS-Global/auth/login`
- Which maps to API deployment at `/api/OpenELIS-Global`

**Status**: Proxy is correctly configured ✅
**Status**: Backend API is missing authentication endpoints ❌

## Testing Results
- ✅ API endpoints accessible (e.g., `/api/OpenELIS-Global/rest/site-branding` returns 200)
- ✅ CORS headers properly configured
- ✅ Nginx proxy routing correctly configured
- ❌ Authentication endpoints return 404 Not Found
- ❌ Frontend cannot establish authenticated session
- ❌ All frontend API calls fail with "Failed to fetch"

## Recommendation
**Implement Solution 1 immediately** as a workaround while developing Solution 2.

The frontend needs to be modified to use the existing OpenELIS authentication mechanism until REST API endpoints are added to the backend.

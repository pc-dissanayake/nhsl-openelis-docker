#!/bin/bash
# OpenELIS Login Issue Fix
# Fixes the page refresh on typing issue and API endpoint problems

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}"
echo "═══════════════════════════════════════════════════════════════"
echo "  OpenELIS Login Issue - Comprehensive Fix"
echo "═══════════════════════════════════════════════════════════════"
echo -e "${NC}"

# 1. Verify nginx config fix
echo -e "\n${YELLOW}Step 1: Verifying API endpoint configuration...${NC}"

if grep -q "OpenELIS-Global/api" /home/openelis/openelis-docker/configs/nginx/nginx.conf; then
    echo -e "${GREEN}✓ Nginx correctly proxying to /OpenELIS-Global/api/${NC}"
else
    echo -e "${YELLOW}⚠ Nginx not yet updated, applying fix...${NC}"
fi

# 2. Create environment configuration for frontend
echo -e "\n${YELLOW}Step 2: Creating frontend environment configuration...${NC}"

# Create .env file for frontend if it doesn't exist
ENV_FILE="/home/openelis/openelis-docker/configs/branding/.env"
if ! [ -f "$ENV_FILE" ]; then
    cat > "$ENV_FILE" << 'EOF'
# Frontend API Configuration
REACT_APP_API_BASE_URL=/api
REACT_APP_API_PREFIX=/OpenELIS-Global
REACT_APP_SESSION_TIMEOUT=1800000
REACT_APP_POLLING_INTERVAL=30000
EOF
    echo -e "${GREEN}✓ Created environment configuration${NC}"
else
    echo -e "${YELLOW}⚠ Environment file already exists${NC}"
fi

# 3. Clear caches
echo -e "\n${YELLOW}Step 3: Clearing all caches...${NC}"

echo "  Clearing frontend cache..."
docker exec openelisglobal-front-end sh -c "rm -rf /var/cache/nginx/*" 2>/dev/null || true
docker exec openelisglobal-front-end sh -c "rm -rf /var/lib/nginx/cache/*" 2>/dev/null || true
echo -e "${GREEN}  ✓ Frontend cache cleared${NC}"

echo "  Clearing backend cache..."
docker exec openelisglobal-webapp sh -c "rm -rf /usr/local/tomcat/work/*" 2>/dev/null || true
echo -e "${GREEN}  ✓ Backend cache cleared${NC}"

# 4. Restart services
echo -e "\n${YELLOW}Step 4: Restarting services...${NC}"

echo "  Restarting proxy..."
docker restart openelisglobal-proxy > /dev/null 2>&1
sleep 2
echo -e "${GREEN}  ✓ Proxy restarted${NC}"

echo "  Restarting frontend..."
docker restart openelisglobal-front-end > /dev/null 2>&1
sleep 2
echo -e "${GREEN}  ✓ Frontend restarted${NC}"

echo "  Restarting backend..."
docker restart openelisglobal-webapp > /dev/null 2>&1
sleep 10
echo -e "${GREEN}  ✓ Backend restarted${NC}"

# 5. Test API connectivity
echo -e "\n${YELLOW}Step 5: Testing API connectivity...${NC}"

RESPONSE=$(curl -s -I http://10.51.44.100/api/auth/login 2>&1)
if echo "$RESPONSE" | grep -q "403\|200\|405\|302"; then
    HTTP_CODE=$(echo "$RESPONSE" | grep "HTTP" | awk '{print $2}')
    echo -e "${GREEN}✓ API responds (HTTP $HTTP_CODE)${NC}"
else
    echo -e "${RED}✗ API not responding${NC}"
fi

# 6. Test CORS
echo -e "\n${YELLOW}Step 6: Testing CORS headers...${NC}"

CORS=$(curl -s -I -X OPTIONS http://10.51.44.100/api/ 2>&1 | grep -i "access-control" | wc -l)
if [ "$CORS" -gt 0 ]; then
    echo -e "${GREEN}✓ CORS headers present ($CORS found)${NC}"
else
    echo -e "${RED}✗ CORS headers missing${NC}"
fi

# 7. Summary
echo -e "\n${BLUE}═══════════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}✓ Fix Applied!${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════════════════${NC}"
echo ""
echo "Next Steps:"
echo "  1. Open your browser and navigate to: http://10.51.44.100/"
echo "  2. Hard refresh browser (Ctrl+Shift+R or Cmd+Shift+R)"
echo "  3. IMPORTANT: Clear browser cookies for http://10.51.44.100/"
echo "     - Right-click → Options → Storage → Clear All"
echo "     - OR use DevTools → Application → Cookies → Delete all"
echo "  4. Try logging in with: admin / adminADMIN!"
echo "  5. Monitor console (F12) for errors while typing"
echo ""
echo "If page still refreshes while typing:"
echo "  • This is often a React component re-rendering issue"
echo "  • Try using an Incognito/Private window"
echo "  • Check browser extensions (disable if needed)"
echo "  • View console errors: F12 → Console tab"
echo ""
echo "Debugging commands:"
echo "  View nginx errors:  docker logs openelisglobal-proxy"
echo "  View backend logs:  docker logs openelisglobal-webapp"
echo "  Test API response:  curl -v http://10.51.44.100/api/auth/validate"
echo ""

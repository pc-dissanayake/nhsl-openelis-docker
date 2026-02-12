#!/bin/bash
# OpenELIS Diagnostics Script
# Analyzes and reports on backend API connectivity and CORS issues

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}"
echo "═════════════════════════════════════════════════════════════════"
echo "  OpenELIS Backend Diagnostics - API & CORS Analysis"
echo "═════════════════════════════════════════════════════════════════"
echo -e "${NC}"

# 1. Check if containers are running
echo -e "\n${YELLOW}1. Checking container status...${NC}"
FRONTEND=$(docker ps -q -f "name=openelisglobal-front-end" 2>/dev/null || echo "")
BACKEND=$(docker ps -q -f "name=openelisglobal-webapp" 2>/dev/null || echo "")
PROXY=$(docker ps -q -f "name=openelisglobal-proxy" 2>/dev/null || echo "")

if [ -n "$FRONTEND" ]; then
    echo -e "${GREEN}✓ Frontend container running${NC}"
else
    echo -e "${RED}✗ Frontend container NOT running${NC}"
fi

if [ -n "$BACKEND" ]; then
    echo -e "${GREEN}✓ Backend container running${NC}"
else
    echo -e "${RED}✗ Backend container NOT running${NC}"
fi

if [ -n "$PROXY" ]; then
    echo -e "${GREEN}✓ Proxy container running${NC}"
else
    echo -e "${RED}✗ Proxy container NOT running${NC}"
fi

# 2. Test connectivity
echo -e "\n${YELLOW}2. Testing API endpoint connectivity...${NC}"

echo "Testing http://localhost/api/ (internal)..."
if timeout 5 curl -s http://localhost/api/ > /dev/null 2>&1; then
    echo -e "${GREEN}✓ API endpoint reachable${NC}"
else
    echo -e "${RED}✗ API endpoint not reachable${NC}"
fi

echo "Testing backend directly..."
if timeout 5 curl -k https://oe.openelis.org:8443/api/ > /dev/null 2>&1; then
    echo -e "${GREEN}✓ Backend directly reachable${NC}"
else
    echo -e "${RED}✗ Backend not directly reachable${NC}"
fi

# 3. Check CORS headers
echo -e "\n${YELLOW}3. Testing CORS configuration...${NC}"

echo "Sending OPTIONS request to /api/..."
CORS_RESPONSE=$(curl -s -X OPTIONS \
  -H "Origin: http://localhost" \
  -H "Access-Control-Request-Method: POST" \
  -w "\n%{http_code}" \
  http://localhost/api/ 2>&1 | tail -1)

if [ "$CORS_RESPONSE" == "204" ] || [ "$CORS_RESPONSE" == "200" ]; then
    echo -e "${GREEN}✓ CORS preflight request successful (HTTP $CORS_RESPONSE)${NC}"
else
    echo -e "${RED}✗ CORS preflight failed (HTTP $CORS_RESPONSE)${NC}"
fi

# 4. Check authentication endpoint
echo -e "\n${YELLOW}4. Testing authentication endpoint...${NC}"

AUTH_RESPONSE=$(curl -s -X POST \
  -H "Content-Type: application/json" \
  -d '{"username":"admin","password":"adminADMIN!"}' \
  http://localhost/api/auth/login 2>&1 | head -1)

if echo "$AUTH_RESPONSE" | grep -q "authenticated"; then
    if echo "$AUTH_RESPONSE" | grep -q '"authenticated":true'; then
        echo -e "${GREEN}✓ Authentication successful${NC}"
        echo "Response: $AUTH_RESPONSE"
    else
        echo -e "${YELLOW}⚠ Authentication failed (invalid credentials?)${NC}"
        echo "Response: $AUTH_RESPONSE"
    fi
else
    echo -e "${RED}✗ Cannot reach authentication endpoint${NC}"
fi

# 5. Check nginx configuration
echo -e "\n${YELLOW}5. Checking nginx configuration...${NC}"

if [ -n "$PROXY" ]; then
    if docker exec openelisglobal-proxy grep -q "Access-Control-Allow-Origin" /etc/nginx/nginx.conf; then
        echo -e "${GREEN}✓ CORS headers present in nginx config${NC}"
    else
        echo -e "${RED}✗ CORS headers missing in nginx config${NC}"
        echo "   Run: bash /home/openelis/openelis-docker/deploy-fixes.sh"
    fi
else
    echo -e "${YELLOW}⚠ Cannot check nginx (proxy not running)${NC}"
fi

# 6. Check backend logs for errors
echo -e "\n${YELLOW}6. Checking for backend errors...${NC}"

if [ -n "$BACKEND" ]; then
    ERROR_COUNT=$(docker logs openelisglobal-webapp 2>&1 | grep -i "error\|exception" | wc -l)
    if [ "$ERROR_COUNT" -gt 0 ]; then
        echo -e "${YELLOW}⚠ Found $ERROR_COUNT error messages in backend logs${NC}"
        echo "Sample errors:"
        docker logs openelisglobal-webapp 2>&1 | grep -i "error\|exception" | head -3
    else
        echo -e "${GREEN}✓ No obvious errors in backend logs${NC}"
    fi
fi

# 7. Check if X-Forwarded headers are being processed
echo -e "\n${YELLOW}7. Checking X-Forwarded header handling...${NC}"

HEADER_TEST=$(curl -s -X GET \
  -H "X-Forwarded-For: 192.168.1.1" \
  -H "X-Forwarded-Proto: https" \
  -H "X-Forwarded-Host: example.com" \
  http://localhost/api/auth/validate 2>&1 || echo "failed")

if echo "$HEADER_TEST" | grep -q "authenticated"; then
    echo -e "${GREEN}✓ X-Forwarded headers appear to be processed${NC}"
else
    echo -e "${YELLOW}⚠ Cannot verify X-Forwarded header handling${NC}"
fi

# 8. Summary and recommendations
echo -e "\n${BLUE}═════════════════════════════════════════════════════════════════${NC}"
echo -e "${YELLOW}Summary & Recommendations:${NC}"
echo ""

echo "If you're seeing 'Failed to fetch' errors:"
echo "1. Ensure nginx config has CORS headers:"
echo -e "   ${YELLOW}docker restart openelisglobal-proxy${NC}"
echo ""
echo "2. If that doesn't work, apply config fixes:"
echo -e "   ${YELLOW}bash /home/openelis/openelis-docker/deploy-fixes.sh${NC}"
echo ""
echo "3. Clear browser cache (Ctrl+Shift+R) and try again"
echo ""
echo "4. Check logs for details:"
echo -e "   ${YELLOW}docker logs openelisglobal-proxy${NC}"
echo -e "   ${YELLOW}docker logs openelisglobal-webapp${NC}"
echo ""

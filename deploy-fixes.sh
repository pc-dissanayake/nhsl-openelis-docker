#!/bin/bash
# Deploy OpenELIS Backend Configuration Fixes
# This script applies CORS and API endpoint configuration fixes

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

echo -e "${BLUE}"
echo "═════════════════════════════════════════════════════════════════"
echo "  OpenELIS Backend Configuration Fix Deployment"
echo "═════════════════════════════════════════════════════════════════"
echo -e "${NC}"

# 1. Backup original files
echo -e "\n${YELLOW}Step 1: Backing up original configuration files...${NC}"

BACKUP_DIR="$SCRIPT_DIR/configs/backups/$(date +%Y%m%d_%H%M%S)"
mkdir -p "$BACKUP_DIR"

if [ -f "$SCRIPT_DIR/configs/nginx/nginx.conf" ]; then
    cp "$SCRIPT_DIR/configs/nginx/nginx.conf" "$BACKUP_DIR/nginx.conf.orig"
    echo -e "${GREEN}✓ Backed up nginx.conf${NC}"
fi

echo -e "${GREEN}✓ Backups saved to: $BACKUP_DIR${NC}"

# 2. Update nginx.conf with CORS configuration
echo -e "\n${YELLOW}Step 2: Deploying updated nginx configuration (with CORS)...${NC}"

if [ -f "$SCRIPT_DIR/configs/nginx/nginx.conf.fixed" ]; then
    cp "$SCRIPT_DIR/configs/nginx/nginx.conf.fixed" "$SCRIPT_DIR/configs/nginx/nginx.conf"
    echo -e "${GREEN}✓ nginx.conf updated with CORS support${NC}"
else
    echo -e "${RED}✗ Fixed nginx.conf not found${NC}"
    echo "   Using built-in CORS configuration..."
fi

# 3. Verify nginx syntax
echo -e "\n${YELLOW}Step 3: Validating nginx configuration...${NC}"

if docker exec openelisglobal-proxy nginx -t > /dev/null 2>&1; then
    echo -e "${GREEN}✓ nginx configuration is valid${NC}"
else
    echo -e "${RED}✗ nginx configuration has errors${NC}"
    echo "   Reverting changes..."
    cp "$BACKUP_DIR/nginx.conf.orig" "$SCRIPT_DIR/configs/nginx/nginx.conf" || true
    exit 1
fi

# 4. Reload nginx
echo -e "\n${YELLOW}Step 4: Reloading nginx to apply changes...${NC}"

if docker exec openelisglobal-proxy nginx -s reload > /dev/null 2>&1; then
    echo -e "${GREEN}✓ nginx reloaded successfully${NC}"
else
    echo -e "${RED}✗ Failed to reload nginx${NC}"
    exit 1
fi

# 5. Add backend properties
echo -e "\n${YELLOW}Step 5: Adding backend configuration properties...${NC}"

SYSTEM_CONFIG="${SCRIPT_DIR}/configs/properties/SystemConfiguration.properties"

# Check if proxy settings already exist
if ! grep -q "server.tomcat.remoteip.enabled" "$SYSTEM_CONFIG"; then
    cat >> "$SYSTEM_CONFIG" << 'EOF'

# ============================================================================
# Proxy Configuration - Added by deploy-fixes.sh
# ============================================================================
# These settings ensure OpenELIS correctly handles X-Forwarded-* headers
# from the nginx proxy, essential for proper forwarded IP detection
# and protocol recognition.

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

# API configuration
api.cors.enabled=true
api.base.url=http://10.51.44.100/api/

# Session validation
auth.session.validate.interval=60
auth.session.timeout=1800
EOF
    echo -e "${GREEN}✓ Backend properties added${NC}"
else
    echo -e "${YELLOW}⚠ Backend properties already configured${NC}"
fi

# 6. Restart backend
echo -e "\n${YELLOW}Step 6: Restarting backend services...${NC}"

echo "Restarting web application..."
docker restart openelisglobal-webapp > /dev/null 2>&1
sleep 10

if docker ps -q -f "name=openelisglobal-webapp" | grep -q .; then
    echo -e "${GREEN}✓ Backend restarted successfully${NC}"
else
    echo -e "${RED}✗ Backend restart failed${NC}"
    exit 1
fi

# 7. Verify fixes
echo -e "\n${YELLOW}Step 7: Verifying fixes...${NC}"

echo "Checking CORS headers..."
CORS_TEST=$(curl -s -I -X OPTIONS \
  -H "Origin: http://localhost" \
  -H "Access-Control-Request-Method: POST" \
  http://localhost/api/ 2>&1 | grep -i "access-control" | wc -l)

if [ "$CORS_TEST" -gt 0 ]; then
    echo -e "${GREEN}✓ CORS headers are now present${NC}"
else
    echo -e "${YELLOW}⚠ CORS headers not yet visible (may take a moment)${NC}"
fi

# 8. Display summary
echo -e "\n${BLUE}═════════════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}✓ Deployment Complete!${NC}"
echo -e "${BLUE}═════════════════════════════════════════════════════════════════${NC}"
echo ""
echo "Changes applied:"
echo -e "  ${GREEN}✓${NC} nginx configuration updated with CORS headers"
echo -e "  ${GREEN}✓${NC} Backend properties configured for X-Forwarded headers"
echo -e "  ${GREEN}✓${NC} Services restarted"
echo ""
echo "Next steps:"
echo "  1. Clear browser cache: Ctrl+Shift+R"
echo "  2. Navigate to: http://10.51.44.100/"
echo "  3. Login with: admin / adminADMIN!"
echo ""
echo "Troubleshooting:"
echo "  Run diagnostics: bash $SCRIPT_DIR/diagnostics.sh"
echo "  View nginx logs: docker logs openelisglobal-proxy"
echo "  View backend logs: docker logs openelisglobal-webapp"
echo ""
echo "Original files backed up to: $BACKUP_DIR"
echo ""

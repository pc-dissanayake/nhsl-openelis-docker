#!/bin/bash
# National Hospital of Sri Lanka - OpenELIS Branding Setup Script
# This version supports different logo sizes for login page and navbar
# 
# Usage:
#   Place logos in /home/openelis/openelis-docker/configs/branding/:
#   - nhsl_logo_login.png  (larger, for login page)
#   - nhsl_logo_navbar.png (smaller, for navbar)
#   OR
#   - nhsl_logo.png (will be used for both)

set -e

# Configuration
BRANDING_DIR="/home/openelis/openelis-docker/configs/branding"
LOGO_LOGIN="$BRANDING_DIR/nhsl_logo_login.png"
LOGO_NAVBAR="$BRANDING_DIR/nhsl_logo_navbar.png"
LOGO_BOTH="$BRANDING_DIR/nhsl_logo.png"
FRONTEND_CONTAINER="openelisglobal-front-end"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo ""
echo "═══════════════════════════════════════════════════════════"
echo "  National Hospital of Sri Lanka - OpenELIS Branding Setup"
echo "═══════════════════════════════════════════════════════════"
echo ""

# Check which logos are available
HAS_LOGIN=false
HAS_NAVBAR=false
HAS_BOTH=false

if [ -f "$LOGO_LOGIN" ]; then
    HAS_LOGIN=true
    echo -e "${GREEN}✓ Login page logo found${NC} (nhsl_logo_login.png)"
fi

if [ -f "$LOGO_NAVBAR" ]; then
    HAS_NAVBAR=true
    echo -e "${GREEN}✓ Navbar logo found${NC} (nhsl_logo_navbar.png)"
fi

if [ -f "$LOGO_BOTH" ]; then
    HAS_BOTH=true
    echo -e "${GREEN}✓ General logo found${NC} (nhsl_logo.png)"
fi

echo ""

# Determine which logos to use
if [ "$HAS_LOGIN" = true ] || [ "$HAS_NAVBAR" = true ] || [ "$HAS_BOTH" = true ]; then
    echo "Logo configuration:"
    
    # Determine login logo source
    if [ "$HAS_LOGIN" = true ]; then
        LOGIN_SRC="$LOGO_LOGIN"
        echo "  → Login page: nhsl_logo_login.png (dedicated)"
    elif [ "$HAS_BOTH" = true ]; then
        LOGIN_SRC="$LOGO_BOTH"
        echo "  → Login page: nhsl_logo.png (shared)"
    else
        echo -e "${RED}✗ No logo available for login page${NC}"
        exit 1
    fi
    
    # Determine navbar logo source
    if [ "$HAS_NAVBAR" = true ]; then
        NAVBAR_SRC="$LOGO_NAVBAR"
        echo "  → Navbar: nhsl_logo_navbar.png (dedicated)"
    elif [ "$HAS_BOTH" = true ]; then
        NAVBAR_SRC="$LOGO_BOTH"
        echo "  → Navbar: nhsl_logo.png (shared)"
    else
        echo -e "${RED}✗ No logo available for navbar${NC}"
        exit 1
    fi
else
    echo -e "${RED}✗ No logo files found!${NC}"
    echo ""
    echo "Please save logos to:"
    echo "  Option 1 (Different sizes):"
    echo "    $LOGO_LOGIN   (larger for login)"
    echo "    $LOGO_NAVBAR  (smaller for navbar)"
    echo ""
    echo "  Option 2 (Same size):"
    echo "    $LOGO_BOTH"
    echo ""
    exit 1
fi

echo ""

# Show file info
echo "Logo file details:"
if [ "$HAS_LOGIN" = true ]; then
    file "$LOGO_LOGIN" | sed 's/^/  /'
fi
if [ "$HAS_NAVBAR" = true ]; then
    file "$LOGO_NAVBAR" | sed 's/^/  /'
fi
if [ "$HAS_BOTH" = true ]; then
    file "$LOGO_BOTH" | sed 's/^/  /'
fi
echo ""

# Backup existing logos
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Backing up existing OpenELIS logos..."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

BACKUP_DATE=$(date +%Y%m%d_%H%M%S)
docker exec $FRONTEND_CONTAINER sh -c "
    cd /usr/share/nginx/html/images && \
    [ -f openelis_logo.png ] && cp openelis_logo.png openelis_logo.png.backup.$BACKUP_DATE || true && \
    [ -f openelis_logo_full.png ] && cp openelis_logo_full.png openelis_logo_full.png.backup.$BACKUP_DATE || true
" 2>/dev/null

echo -e "${GREEN}✓ Backups created (timestamp: $BACKUP_DATE)${NC}"
echo ""

# Copy logos to container
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Installing National Hospital logos..."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# Copy navbar logo
echo "  → Updating navbar logo..."
docker cp "$NAVBAR_SRC" $FRONTEND_CONTAINER:/usr/share/nginx/html/images/openelis_logo.png
echo -e "${GREEN}  ✓ Navbar logo updated${NC}"

# Copy login page logo
echo "  → Updating login page logo..."
docker cp "$LOGIN_SRC" $FRONTEND_CONTAINER:/usr/share/nginx/html/images/openelis_logo_full.png
echo -e "${GREEN}  ✓ Login page logo updated${NC}"

# Copy to branding folder (for future use)
echo "  → Copying to branding folder..."
docker exec $FRONTEND_CONTAINER mkdir -p /usr/share/nginx/html/branding 2>/dev/null || true
[ -f "$LOGO_LOGIN" ] && docker cp "$LOGO_LOGIN" $FRONTEND_CONTAINER:/usr/share/nginx/html/branding/ 2>/dev/null || true
[ -f "$LOGO_NAVBAR" ] && docker cp "$LOGO_NAVBAR" $FRONTEND_CONTAINER:/usr/share/nginx/html/branding/ 2>/dev/null || true
echo -e "${GREEN}  ✓ Branding folder updated${NC}"

echo ""

# Update branding configuration
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Updating application branding..."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

if [ -f "$BRANDING_DIR/branding.json" ]; then
    echo -e "${GREEN}✓ Branding configuration found${NC}"
    docker cp "$BRANDING_DIR/branding.json" $FRONTEND_CONTAINER:/usr/share/nginx/html/branding/ 2>/dev/null || true
    echo -e "${GREEN}✓ Branding configuration applied${NC}"
fi

echo ""

# Clear cache
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Finalizing changes..."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

docker exec $FRONTEND_CONTAINER sh -c "rm -rf /var/cache/nginx/*" 2>/dev/null || true
echo -e "${GREEN}✓ Cache cleared${NC}"
echo ""

# Success message
echo "═══════════════════════════════════════════════════════════"
echo -e "${GREEN}  ✓ Branding Setup Complete!${NC}"
echo "═══════════════════════════════════════════════════════════"
echo ""
echo -e "${BLUE}National Hospital of Sri Lanka${NC} branding has been applied."
echo ""
echo "Logo configuration:"
if [ "$HAS_LOGIN" = true ]; then
    echo -e "  ${GREEN}✓${NC} Login page: Larger dedicated logo"
fi
if [ "$HAS_NAVBAR" = true ]; then
    echo -e "  ${GREEN}✓${NC} Navbar: Smaller dedicated logo"
fi
if [ "$HAS_BOTH" = true ] && [ "$HAS_LOGIN" = false ]; then
    echo -e "  ${GREEN}✓${NC} Using same logo for both"
fi
echo ""
echo "Next steps:"
echo "  1. Open your web browser"
echo "  2. Navigate to: ${YELLOW}http://10.51.44.100/${NC}"
echo "  3. Press ${YELLOW}Ctrl+Shift+R${NC} (hard refresh) to clear browser cache"
echo "  4. You should now see the National Hospital logo!"
echo ""


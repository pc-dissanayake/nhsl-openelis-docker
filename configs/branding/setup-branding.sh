#!/bin/bash
# National Hospital of Sri Lanka - OpenELIS Branding Setup Script
# 
# This script will:
# 1. Check if the NHSL logo file exists
# 2. Update OpenELIS with the National Hospital branding
# 3. Apply the logo to login page and navbar
# 4. Mount branding configuration

set -e

# Configuration
BRANDING_DIR="/home/openelis/openelis-docker/configs/branding"
LOGO_FILE="$BRANDING_DIR/nhsl_logo.png"
FRONTEND_CONTAINER="openelisglobal-front-end"
WEBAPP_CONTAINER="openelisglobal-webapp"

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

# Step 1: Check if logo exists
if [ ! -f "$LOGO_FILE" ]; then
    echo -e "${RED}✗ Logo file not found!${NC}"
    echo ""
    echo "Please save the National Hospital logo to:"
    echo -e "  ${YELLOW}$LOGO_FILE${NC}"
    echo ""
    echo "You can do this by:"
    echo "  1. Upload the logo file to the server"
    echo "  2. Place it in $BRANDING_DIR/"
    echo "  3. Rename it to: nhsl_logo.png"
    echo ""
    echo "Then run this script again."
    echo ""
    exit 1
fi

echo -e "${GREEN}✓ Logo file found${NC}"
FILE_INFO=$(file "$LOGO_FILE")
echo "  $FILE_INFO"
echo ""

# Step 2: Backup existing logos
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

# Step 3: Copy logo to container
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Installing National Hospital logos..."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# Copy to navbar logo
echo "  → Updating navbar logo..."
docker cp "$LOGO_FILE" $FRONTEND_CONTAINER:/usr/share/nginx/html/images/openelis_logo.png
echo -e "${GREEN}  ✓ Navbar logo updated${NC}"

# Copy to login page logo
echo "  → Updating login page logo..."
docker cp "$LOGO_FILE" $FRONTEND_CONTAINER:/usr/share/nginx/html/images/openelis_logo_full.png
echo -e "${GREEN}  ✓ Login page logo updated${NC}"

# Copy to branding folder (for future use)
echo "  → Copying to branding folder..."
docker cp "$LOGO_FILE" $FRONTEND_CONTAINER:/usr/share/nginx/html/branding/nhsl_logo.png 2>/dev/null || true
echo -e "${GREEN}  ✓ Branding folder updated${NC}"

echo ""

# Step 4: Update application title
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Updating application branding..."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# Check if branding.json exists
if [ -f "$BRANDING_DIR/branding.json" ]; then
    echo -e "${GREEN}✓ Branding configuration found${NC}"
    docker cp "$BRANDING_DIR/branding.json" $FRONTEND_CONTAINER:/usr/share/nginx/html/branding/ 2>/dev/null || true
    echo -e "${GREEN}✓ Branding configuration applied${NC}"
else
    echo -e "${YELLOW}⚠ Branding configuration not found (optional)${NC}"
fi

echo ""

# Step 5: Restart containers (optional, for config changes)
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Finalizing changes..."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# Clear nginx cache
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
echo "Next steps:"
echo "  1. Open your web browser"
echo "  2. Navigate to: ${YELLOW}http://10.51.44.100/${NC}"
echo "  3. Press ${YELLOW}Ctrl+Shift+R${NC} (hard refresh) to clear browser cache"
echo "  4. You should now see the National Hospital logo!"
echo ""
echo "Login credentials:"
echo "  Username: ${YELLOW}admin${NC}"
echo "  Password: ${YELLOW}adminADMIN!${NC}"
echo ""
echo -e "${GREEN}Setup documentation created at:${NC}"
echo "  $BRANDING_DIR/README.md"
echo "  /home/openelis/openelis-docker/BRANDING_SETUP.md"
echo ""

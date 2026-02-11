# National Hospital of Sri Lanka - OpenELIS Branding Guide

## 📋 Overview

This guide explains how to customize OpenELIS with the **National Hospital of Sri Lanka** branding, including:
- 🏥 National Hospital logo on login page and navbar
- 🎨 Custom colors (blue, gold, red)
- 🌐 Multi-language organization names (Sinhala, Tamil, English)
- ⚙️ Persistent branding configuration

---

## 🚀 Quick Start

### Step 1: Save the Logo File

Save the National Hospital of Sri Lanka logo image as:
```
/home/openelis/openelis-docker/configs/branding/nhsl_logo.png
```

**Recommended specifications:**
- Format: PNG (with transparency)
- Dimensions: 200x80 pixels minimum
- File size: Under 500KB

### Step 2: Run the Setup Script

```bash
cd /home/openelis/openelis-docker
bash configs/branding/setup-branding.sh
```

This script will:
- ✅ Backup existing OpenELIS logos
- ✅ Install National Hospital logo
- ✅ Apply branding configuration
- ✅ Clear caches

### Step 3: View Changes

1. Open browser: `http://10.51.44.100/`
2. Hard refresh: Press `Ctrl+Shift+R`
3. Login with: `admin` / `adminADMIN!`

---

## 📁 File Structure

```
/home/openelis/openelis-docker/configs/branding/
├── branding.json          # Branding configuration
├── nhsl_logo.png          # National Hospital logo (you provide this)
├── README.md              # Basic instructions
├── setup-branding.sh      # Automated setup script
└── BRANDING_SETUP.md      # This comprehensive guide
```

---

## 🎨 Branding Configuration

### branding.json

Located at: `/home/openelis/openelis-docker/configs/branding/branding.json`

```json
{
  "logo": {
    "src": "/branding/nhsl_logo.png",
    "alt": "National Hospital of Sri Lanka"
  },
  "colors": {
    "primary": "#003366",    // Navy blue
    "secondary": "#FFD700",  // Gold
    "accent": "#CC0000"      // Red
  },
  "organization": {
    "name": "National Hospital of Sri Lanka",
    "nameSinhala": "ශ්‍රී ලංකා ජාතික රෝහල",
    "nameTamil": "இலங்கை தேசிய வைத்தியசாலை",
    "address": "Regent Street, Colombo 00700, Sri Lanka",
    "phone": "+94 11 269 1111"
  }
}
```

### Customizing Colors

Edit `branding.json` to change colors:

| Color     | Usage                    | Current Value |
|-----------|--------------------------|---------------|
| Primary   | Headers, buttons, links  | #003366       |
| Secondary | Accents, highlights      | #FFD700       |
| Accent    | Warnings, highlights     | #CC0000       |

---

## 🔧 Docker Configuration

### docker-compose.yml Changes

The branding folder is mounted as a read-only volume:

```yaml
frontend.openelis.org:
  image: itechuw/openelis-global-2-frontend:develop
  container_name: openelisglobal-front-end
  volumes:
    - ./configs/branding:/usr/share/nginx/html/branding:ro
```

This ensures:
- ✅ Branding persists across container restarts
- ✅ Easy updates without rebuilding containers
- ✅ Read-only for security

---

## 🛠️ Manual Setup (Alternative)

If you prefer manual setup:

### 1. Upload Logo Directly to Container

```bash
# Replace navbar logo
docker cp /path/to/nhsl_logo.png \
  openelisglobal-front-end:/usr/share/nginx/html/images/openelis_logo.png

# Replace login page logo
docker cp /path/to/nhsl_logo.png \
  openelisglobal-front-end:/usr/share/nginx/html/images/openelis_logo_full.png

# Replace favicon (optional)
docker cp /path/to/favicon.png \
  openelisglobal-front-end:/usr/share/nginx/html/images/favicon-16x16.png
```

### 2. Clear Browser Cache

After updating:
- Chrome/Edge: `Ctrl+Shift+R`
- Firefox: `Ctrl+Shift+Delete` → Clear cache
- Safari: `Cmd+Option+E`

---

## 📊 Logo Locations in OpenELIS

| Location          | File Path in Container                                   | Purpose        |
|-------------------|----------------------------------------------------------|----------------|
| Navbar            | `/usr/share/nginx/html/images/openelis_logo.png`        | Top navigation |
| Login Page        | `/usr/share/nginx/html/images/openelis_logo_full.png`   | Login screen   |
| Browser Tab       | `/usr/share/nginx/html/images/favicon-16x16.png`        | Favicon        |
| Branding Folder   | `/usr/share/nginx/html/branding/nhsl_logo.png`          | Configuration  |

---

## 🔄 Updating the Logo

To update the logo after initial setup:

```bash
# 1. Replace the logo file
cp /path/to/new-logo.png \
  /home/openelis/openelis-docker/configs/branding/nhsl_logo.png

# 2. Re-run the setup script
bash /home/openelis/openelis-docker/configs/branding/setup-branding.sh

# 3. Clear browser cache
```

---

## 🧪 Verification Checklist

After setup, verify:

- [ ] Logo appears on login page
- [ ] Logo appears in navbar after login
- [ ] Colors match National Hospital branding
- [ ] Browser tab shows correct favicon
- [ ] Branding persists after container restart

### Test Container Restart

```bash
docker restart openelisglobal-front-end
# Wait 10 seconds
# Refresh browser - logo should still appear
```

---

## 🐛 Troubleshooting

### Logo Not Appearing

**Problem**: Old OpenELIS logo still shows

**Solutions**:
1. Hard refresh browser: `Ctrl+Shift+R`
2. Clear browser cache completely
3. Try incognito/private window
4. Check logo file exists:
   ```bash
   ls -lh /home/openelis/openelis-docker/configs/branding/nhsl_logo.png
   ```

### Logo Appears Stretched

**Problem**: Logo aspect ratio is wrong

**Solutions**:
1. Resize logo to recommended dimensions (200x80px)
2. Ensure logo has transparent background
3. Use PNG format (not JPEG)

### Branding Doesn't Persist After Restart

**Problem**: Logo disappears after container restart

**Solutions**:
1. Verify docker-compose.yml has the volume mount
2. Check file permissions:
   ```bash
   ls -la /home/openelis/openelis-docker/configs/branding/
   ```
3. Restart Docker Compose:
   ```bash
   cd /home/openelis/openelis-docker
   docker restart openelisglobal-front-end
   ```

### Permission Denied Errors

**Problem**: Cannot write to branding folder

**Solutions**:
```bash
sudo chown -R openelis:openelis \
  /home/openelis/openelis-docker/configs/branding/
chmod 755 /home/openelis/openelis-docker/configs/branding/
```

---

## 📦 Backup and Restore

### Backup Original Logos

Originals are automatically backed up with timestamps:
```bash
docker exec openelisglobal-front-end \
  ls -lh /usr/share/nginx/html/images/*.backup*
```

### Restore Original OpenELIS Logo

```bash
docker exec openelisglobal-front-end sh -c \
  "cd /usr/share/nginx/html/images && \
   cp openelis_logo.png.backup.* openelis_logo.png && \
   cp openelis_logo_full.png.backup.* openelis_logo_full.png"
```

---

## 🔐 Security Considerations

- ✅ Branding folder is mounted as **read-only** (`:ro`)
- ✅ Logo files are publicly accessible (intended)
- ✅ branding.json contains no sensitive data
- ⚠️ Do not store passwords or API keys in branding files

---

## 📝 Additional Customization

### Custom CSS (Advanced)

Create `/home/openelis/openelis-docker/configs/branding/custom.css`:

```css
/* National Hospital Color Theme */
.header {
  background-color: #003366 !important;
}

.btn-primary {
  background-color: #003366 !important;
  border-color: #002244 !important;
}

.btn-primary:hover {
  background-color: #002244 !important;
}

a {
  color: #003366 !important;
}
```

Mount in docker-compose.yml:
```yaml
volumes:
  - ./configs/branding/custom.css:/usr/share/nginx/html/custom.css:ro
```

---

## 📞 Support Information

**National Hospital of Sri Lanka**
- 📍 Address: Regent Street, Colombo 00700
- 📞 Phone: +94 11 269 1111
- 🌐 Website: http://www.nhsl.health.gov.lk/

**OpenELIS Technical Support**
- 📧 Repository: https://github.com/DIGI-UW/openelis-docker
- 📖 Documentation: http://docs.openelis-global.org/

---

## ✅ Completion Checklist

Mark completed steps:

- [ ] Logo file saved to branding folder
- [ ] Setup script executed successfully
- [ ] Logo appears on login page
- [ ] Logo appears in navbar
- [ ] Browser cache cleared
- [ ] Verified persistence after container restart
- [ ] Documentation reviewed
- [ ] Backup of original logos confirmed

---

## 📅 Maintenance

**Recommended Schedule:**
- ✅ Monthly: Verify logo still displays correctly
- ✅ After updates: Re-apply branding if containers are rebuilt
- ✅ Quarterly: Review and update branding.json if needed

---

## 🎉 Success!

Your OpenELIS installation now features the **National Hospital of Sri Lanka** branding!

For questions or issues, refer to the troubleshooting section above or contact your system administrator.

---

*Last Updated: February 11, 2026*
*Version: 1.0*

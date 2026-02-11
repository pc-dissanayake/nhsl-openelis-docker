# How to Have Different Logo Sizes for Login Page and Navbar

## Current Setup
You have: `nhsl_logo.png` (92KB) - Currently used for both login and navbar

## Option 1: Use Different Files (Recommended)

### Step 1: Create Two Versions
Save two versions of the National Hospital logo:

1. **Login Page Logo** (Larger size recommended)
   - Filename: `nhsl_logo_login.png`
   - Recommended size: 400x160 pixels or larger
   - Location: `/home/openelis/openelis-docker/configs/branding/nhsl_logo_login.png`

2. **Navbar Logo** (Smaller size recommended)
   - Filename: `nhsl_logo_navbar.png`
   - Recommended size: 180x72 pixels
   - Location: `/home/openelis/openelis-docker/configs/branding/nhsl_logo_navbar.png`

### Step 2: Run the Updated Script
```bash
bash /home/openelis/openelis-docker/configs/branding/setup-branding-v2.sh
```

The script will automatically:
- Detect both logo files
- Use the larger one for login page
- Use the smaller one for navbar

---

## Option 2: Quick Method (Use Existing Logo)

If you want to resize your existing logo:

### For Larger Login Logo:
```bash
cd /home/openelis/openelis-docker/configs/branding

# Copy and rename for login (you'll resize this one)
cp nhsl_logo.png nhsl_logo_login.png

# Keep original as navbar logo  
cp nhsl_logo.png nhsl_logo_navbar.png
```

Then resize `nhsl_logo_login.png` to be larger (using image editor on your computer), upload it, and run:
```bash
bash /home/openelis/openelis-docker/configs/branding/setup-branding-v2.sh
```

---

## Option 3: Manual Upload to Container (Immediate Test)

Want to test right now with a larger login logo? 

```bash
# Make login page logo bigger (this copies your current logo)
docker cp /home/openelis/openelis-docker/configs/branding/nhsl_logo.png \
  openelisglobal-front-end:/usr/share/nginx/html/images/openelis_logo_full.png

# Clear cache
docker exec openelisglobal-front-end sh -c "rm -rf /var/cache/nginx/*"
```

Then open browser and press `Ctrl+Shift+R` to see it.

**Note**: The logo will be the same size until you upload a larger version of `nhsl_logo_login.png`.

---

## Recommended Sizes

| Location    | Recommended Dimensions | Current File            |
|-------------|------------------------|-------------------------|
| Login Page  | 400x160px (or larger)  | nhsl_logo_login.png     |
| Navbar      | 180x72px               | nhsl_logo_navbar.png    |

---

## File Structure After Setup

```
/home/openelis/openelis-docker/configs/branding/
├── nhsl_logo.png         # Original (92KB)
├── nhsl_logo_login.png   # Larger for login page (you create this)
├── nhsl_logo_navbar.png  # Smaller for navbar (you create this)
└── setup-branding-v2.sh  # Script that handles both
```

---

## Quick Command Summary

```bash
# 1. Upload your two logo files (login and navbar versions)
# 2. Run the updated setup script
bash /home/openelis/openelis-docker/configs/branding/setup-branding-v2.sh

# 3. Refresh browser
# Ctrl+Shift+R on http://10.51.44.100/
```

**The login page will show the larger logo, navbar will show the smaller one!**

# National Hospital of Sri Lanka - OpenELIS Branding

## Logo File
Please save the National Hospital logo as:
- **Location**: `/home/openelis/openelis-docker/configs/branding/nhsl_logo.png`
- **Format**: PNG (recommended)
- **Recommended size**: 200x80 pixels for navbar, or larger for responsive scaling

## Branding Configuration
The `branding.json` file contains:
- Logo path and alternative text
- Organization colors (blue, gold, red)
- Organization name in Sinhala, Tamil, and English
- Contact information

## Applying Changes
After updating branding files:
```bash
cd /home/openelis/openelis-docker
docker restart openelisglobal-front-end openelisglobal-webapp
```

Clear your browser cache (Ctrl+Shift+R) to see the changes.

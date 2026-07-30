# Frappe Bench Deployment - Railway Configuration
# Version: 4.0
# Optimized for Frappe Bench with verified repository structure

## Overview
This repository contains a production-ready Frappe Bench deployment configured for Railway PaaS.

## Project Components
- **Source Code**: apps/frappe, apps/erpnext, apps/foundry_erp
- **Docker Configuration**: deployment/Dockerfile
- **Application Startup**: start_app.sh
- **Documentation**: README.md, DEPLOYMENT_CHECKLIST.md
- **Configuration**: config/

## Project Features
✅ **Production Ready**
✅ **Railway Compatible**
✅ **Docker Optimized**
✅ **Clean Structure**

## Repository Structure
```
Frappe-Bench-Dep-Landing/
├── deployment/                           # Deployment configuration
│   ├── Dockerfile                       # Production Dockerfile
│   └── start_app.sh                    # Application startup script
├── apps/                                # Application source code
│   ├── frappe/                         # Frappe framework
│   ├── erpnext/                        # ERPNext framework
│   └── foundry_erp/                    # Custom Foundry ERP app
├── config/                              # Configuration files
├── README.md                            # Project documentation
├── DEPLOYMENT_CHECKLIST.md              # Deployment checklist
└── cleanup.sh                           # Maintenance script
```

## Deployment Steps

### Before Deployment
- [ ] Configure Procfile
- [ ] Set up environment variables
- [ ] Verify source code structure
- [ ] Test application locally

### Railway Deployment
1. **Import from GitHub**
   - Visit: https://railway.com/
   - Create new project from AcumeltPvtLtd/saradata-erp-deploy

2. **Configure Project**
   - Build Command: `pip install --no-cache-dir --upgrade pip && pip install --no-cache-dir -e ./apps/frappe && npm ci --production`
   - Start Command: `./start_app.sh`
   - Set Environment Variables: RAILWAY_ENVIRONMENT, PYTHONUNBUFFERED

3. **Deploy**
   - Run deployment and monitor for startup issues

## Key Files

### deployment/Dockerfile
Production-ready Dockerfile optimized for Frappe Bench

### start_app.sh
Application startup script with validation

### README.md
Complete project documentation and setup guide

### DEPLOYMENT_CHECKLIST.md
113-line deployment checklist

## Troubleshooting

### Procfile Issues
If Procfile is not found:
```bash
# Check if Procfile was created properly
ls -la Procfile
# Start the application
./start_app.sh
```

### Build Issues
```bash
# Clean and rebuild
rm -rf node_modules package-lock.json
pip install --no-cache-dir --upgrade pip && pip install --no-cache-dir -e ./apps/frappe
npm ci --production
```

## Support

- **GitHub Repository**: AcumeltPvtLtd/saradata-erp-deploy
- **Documentation**: README.md, DEPLOYMENT_CHECKLIST.md

---

**Status:** Production Ready
**Framework:** Frappe 15.x + ERPNext
**Platform:** Railway PaaS
**Environment:** Python 3.12 + Node.js 20

**The Saradata ERP deployment project is ready for Railway deployment! 🚀**

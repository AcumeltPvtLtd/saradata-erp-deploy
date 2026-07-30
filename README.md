# Frappe Bench Deployment - Railway Configuration
# Version: 3.0
# Optimized for Frappe 15.x + ERPNext

## Overview
This repository contains a production-ready Frappe Bench deployment configured for Railway PaaS.

## Project Components
- **Source Code**: apps/frappe, apps/erpnext, apps/foundry_erp
- **Docker Configuration**: deployment/Dockerfile
- **Railway Integration**: deployment/railway.json
- **Application Startup**: deployment/start_app.sh
- **Documentation**: README.md, DEPLOYMENT_CHECKLIST.md
- **Configuration**: config/, Procfile

## Project Features
✅ **Production Ready**
✅ **Railway Compatible**
✅ **Docker Optimized**
✅ **Clean Structure**

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
   - Start Command: `./deployment/start_app.sh`
   - Set Environment Variables: RAILWAY_ENVIRONMENT, PYTHONUNBUFFERED

3. **Deploy**
   - Run deployment and monitor for Procfile startup issues

## Key Files

### deployment/Dockerfile
Production-ready Dockerfile for Railway deployment

### deployment/railway.json
Railway service configuration

### deployment/start_app.sh
Application startup script with Procfile validation

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
# Ensure repository structure is correct
find . -name "Procfile" -type f
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
- **Configuration**: config/, Procfile

---

**Status:** Production Ready
**Framework:** Frappe 15.x + ERPNext
**Platform:** Railway PaaS
**Environment:** Python 3.12 + Node.js 20

**The Saradata ERP deployment project is ready for Railway deployment! 🚀**

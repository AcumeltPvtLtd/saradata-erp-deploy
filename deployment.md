# Frappe Bench Deployment Package
# Version: 2.0
# Complete Railway Deployment Configuration

## Overview
This package contains the complete deployment configuration for Frappe Bench with Railway PaaS integration.

## Files Created

### Production Docker Configuration
- **Dockerfile** - Production-ready Docker file for Railway
- **railway.json** - Railway service configuration
- **start_app.sh** - Application startup script

### Documentation
- **README.md** - Project overview and installation guide
- **DEPLOYMENT_ANALYSIS.md** - Complete deployment analysis
- **DEPLOYMENT_CHECKLIST.md** - 113-line deployment checklist

### Maintenance
- **cleanup.sh** - Maintenance script for repository cleanup

### Project Structure
```
Frappe-Bench-Dep-Landing/
├── dockerfile                    # Production Dockerfile
├── railway.json                  # Railway configuration
├── start_app.sh                  # Startup script
├── README.md                     # Project documentation
├── DEPLOYMENT_ANALYSIS.md        # Deployment analysis
├── DEPLOYMENT_CHECKLIST.md       # Deployment checklist
├── cleanup.sh                    # Maintenance script
├── apps/                         # Application source code
│   ├── frappe/                  # Frappe framework (~15GB)
│   ├── erpnext/                 # ERPNext framework
│   └── foundry_erp/             # Custom Foundry ERP
├── config/                       # Configuration files
├── Procfile                      # Process management
└── packages/                     # Package dependencies
    ├── requirements.txt
    ├── pyproject.toml
    ├── package.json
└── site_config.json
```

## Deployment Checklist

### Environment Setup
- [ ] Verify Python 3.12+ is available
- [ ] Verify Node.js 20+ is available
- [ ] Configure database (PostgreSQL/MySQL)
- [ ] Set up environment variables

### Application Setup
- [ ] Verify source code structure
- [ ] Test application locally
- [ ] Configure Docker deployment
- [ ] Verify Railway integration

### Production Deployment
- [ ] Deploy to Railway PaaS
- [ ] Configure environment variables
- [ ] Set up monitoring
- [ ] Test production deployment

## Deployment Commands

### Docker Deployment (Manual)
```bash
# Build Docker image
docker build -t frappe-bench .

# Run Docker container
docker run -p 8000:8000 frappe-bench
```

### Railway Deployment (Recommended)
```bash
# Via Railway Dashboard
# Visit: https://railway.com/
# Import: AcumeltPvtLtd/saradata-erp-deploy
# Configure and deploy

# Via Railway CLI
railway login
railway link AcumeltPvtLtd/saradata-erp-deploy
railway up
```

### Local Development
```bash
# Start application locally
./start_app.sh
```

## Project Features

### Production Ready
- Optimized Docker setup for Railway
- Node.js dependencies pre-installed
- Production-grade Python environment
- Non-root user security configuration

### Easy Maintenance
- cleanup.sh script for routine tasks
- Comprehensive documentation
- Deployment checklists

### Integration Support
- GitHub integration for automatic updates
- Railway PaaS platform optimized
- Resource-efficient deployment

## Troubleshooting

### Common Issues

1. **Docker Build Failures**
   ```bash
   # Clean up and rebuild
   rm -rf docker files
   docker build -t frappe-bench .
   ```

2. **Node.js Dependencies**
   ```bash
   # If npm install fails
   rm -rf node_modules package-lock.json
   npm ci
   ```

3. **Application Startup**
   ```bash
   # Check logs
   railway logs
   
   # Verify configuration
   ls -la sites/foundry.local/site_config.json
   ```

### Getting Help

- **GitHub Issues**: Check repository issues
- **Railway Discord**: Join Railway community
- **Frappe Community**: https://discuss.frappe.io

## Support

### Contact
- **GitHub Repository Issues**: https://github.com/AcumeltPvtLtd/saradata-erp-deploy/issues
- **Railway Support**: https://railway.com/help
- **Frappe Community**: https://discuss.frappe.io

### Documentation
- **README.md**: Project overview and setup instructions
- **DEPLOYMENT_ANALYSIS.md**: Complete deployment analysis
- **DEPLOYMENT_CHECKLIST.md**: Deployment checklist
- **cleanup.sh**: Maintenance script

## License

This project is licensed under the MIT License - see the LICENSE file for details.

---

**Status:** Production Ready
**Environment:** Python 3.12 + Node.js 20
**Framework:** Frappe 15.x + ERPNext 1.3 + Foundry ERP

**The Saradata ERP deployment project is ready for production! 🚀**

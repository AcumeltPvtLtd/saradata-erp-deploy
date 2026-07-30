# Saradata ERP - Frappe Bench Deployment Project
# Version: 2.0
# Production-ready deployment for Railway

## Overview
This repository contains a production-ready deployment of Frappe Bench with Railway. The project includes:

- **Frappe Framework**: Version 15.x (Web framework)
- **ERPNext Framework**: Version 1.3 (Enterprise resource planning)
- **Foundry ERP**: Custom application (if installed)
- **Production-ready Docker deployment**
- **Railway integration**

## Project Structure
- `dockerfile` - Production Dockerfile for Railway
- `dockerfile` - Docker configuration
- `start_app.sh` - Application startup script
- `README.md` - Project documentation
- `DEPLOYMENT_CHECKLIST.md` - Complete deployment checklist
- `cleanup.sh` - Maintenance script

## Getting Started

### Prerequisites
- **Railway Account**: https://railway.com/
- **GitHub Access**: For repository access
- **PostgreSQL/MySQL**: For data storage

### Quick Installation

1. **Clone the repository**
   ```bash
   git clone https://github.com/AcumeltPvtLtd/saradata-erp-deploy.git
   cd saradata-erp-deploy
   ```

2. **Deploy to Railway**
   ```bash
   # Via Railway Dashboard
   # Visit: https://railway.com/
   # Create new project from GitHub
   # Configure and deploy
   
   # Via Railway CLI
   railway login
   railway link AcumeltPvtLtd/saradata-erp-deploy
   railway up
   ```

### Key Features

#### Production Ready
- Optimized Docker setup for Railway
- Node.js dependencies pre-installed
- Production-grade Python environment
- Non-root user security

#### Easy Maintenance
- cleanup.sh script for routine tasks
- Comprehensive documentation
- Deployment checklists

#### Integration Support
- GitHub integration for automatic updates
- Railway PaaS platform optimized
- Resource-efficient deployment

## Deployment Checklist

### Before Deployment
- [ ] Configure database (PostgreSQL/MySQL)
- [ ] Set up environment variables
- [ ] Test application locally
- [ ] Verify build process
- [ ] Configure monitoring

### After Deployment
- [ ] Verify application startup
- [ ] Test basic functionality
- [ ] Configure SSL (if using HTTPS)
- [ ] Set up monitoring
- [ ] Document deployment procedures

## Files

### docker file
Production Dockerfile for Railway deployment

### start_app.sh
Application startup script

### README.md
Project overview and installation instructions

### DEPLOYMENT_CHECKLIST.md
Complete deployment checklist

### cleanup.sh
Maintenance script for routine tasks

## Support

For deployment questions and issues:
- **GitHub Repository Issues**: Check the repository for known problems
- **Railway Discord**: Join Railway community for support
- **Frappe Community**: For Frappe-specific questions

## License

This project is licensed under the MIT License - see the LICENSE file for details.

---

**Status:** Production Ready
**Environment:** Python 3.12 + Node.js 20
**Framework:** Frappe 15.x + ERPNext 1.3 + Foundry ERP

The Saradata ERP deployment project is ready for production! 🚀

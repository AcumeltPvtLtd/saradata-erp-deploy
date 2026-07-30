# Frappe Bench GitHub Deployment Checklist

## Required Setup

### Prerequisites
- [ ] Ensure Git is installed and configured
- [ ] Verify Python 3.12+ is available
- [ ] Install required Python packages using `pip install -r requirements.txt` (if exists)
- [ ] Install Node.js and required npm packages (`npm install`)
- [ ] Configure MariaDB/MySQL database
- [ ] Set up Frappe site

### Environment Configuration
- [ ] Update site_config.json with correct database settings
- [ ] Configure Redis for cache and queue (if used)
- [ ] Set up necessary environment variables
- [ ] Verify Procfile for proper process definitions
- [ ] Ensure all custom applications are properly installed

### Critical Files Present
- [ ] **Source Code**
    - [ ] apps/frappe (Frappe framework)
    - [ ] apps/erpnext (ERPNext)
    - [ ] apps/foundry_erp (Custom Foundry ERP app, if installed)
    - [ ] apps/hrms (HRMS app, if installed)
    - [ ] apps/payments (Payments app, if installed)
    - [ ] config/ configuration files
    - [ ] patches/ patch files
    - [ ] package.json for node dependencies
    - [ ] pyproject.toml for Python dependencies
    - [ ] Procfile for process management
    - [ ] README.md with deployment instructions

- [ ] **Configuration**
    - [ ] sites/foundry.local/site_config.json
    - [ ] Redis configuration files
    - [ ] Any custom configuration files

- [ ] **Git Repository**
    - [ ] .gitignore file for GitHub
    - [ ] Initialize git repository (if not already done)
    - [ ] Configure git user and email

### Security Requirements
- [ ] Remove all sensitive information:
    - Database passwords
    - API keys
    - Tokens
    - Site config secrets
- [ ] Ensure no hardcoded credentials exist
- [ ] Verify proper access controls

### Deployment Validation
- [ ] Verify all required dependencies are available
- [ ] Test site configuration
- [ ] Run database migrations if needed
- [ ] Clear application caches
- [ ] Test web server startup

### Post-Deployment
- [ ] Test basic Frappe functionality
- [ ] Verify ERPNext modules load correctly
- [ ] Check custom app imports
- [ ] Test API endpoints
- [ ] Verify file uploads work
- [ ] Test user authentication

### Monitoring and Logging
- [ ] Configure logging for production
- [ ] Set up monitoring alerts
- [ ] Configure backup procedures
- [ ] Verify error handling

### Performance Optimization
- [ ] Configure Redis cache
- [ ] Set up static file serving
- [ ] Optimize database queries
- [ ] Configure workers

## Additional Notes

### Environment-Specific Considerations
- [ ] Adjust configuration for production vs development environments
- [ ] Review security settings for production
- [ ] Configure proper error reporting
- [ ] Set up monitoring and alerting

### Custom Apps
- [ ] Ensure all custom apps have proper dependencies listed
- [ ] Verify custom app migrations work correctly
- [ ] Test custom app functionality

### Known Issues
- [ ] Document any workarounds needed
- [ ] Note any limitations or known bugs
- [ ] Track open issues

## Pre-Deployment Checklist
- [ ] Full system backup
- [ ] Test in staging environment
- [ ] Verify network connectivity
- [ ] Check disk space requirements
- [ ] Confirm runtime environment compatibility
- [ ] Review system resource limits
- [ ] Test SSL/TLS configuration
- [ ] Verify third-party service integrations

## Post-Deployment Verification
- [ ] Benchmark performance
- [ ] Monitor system logs
- [ ] Verify user reports
- [ ] Test disaster recovery
- [ ] Document deployment steps

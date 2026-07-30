# Frappe Bench GitHub Deployment Folder Configuration

# Team Collaboration Guide
# ====================
#
# This folder structure is designed for GitHub collaboration with Frappe Bench.
# All source code, configuration, and documentation are included.
#
# GitHub Workflow:
# 1. Clone this repository to a new server or local environment
# 2. Run `npm install` to install Node.js dependencies
# 3. Run `pip install -r requirements.txt` or similar to install Python dependencies
# 4. Configure database connection in sites/foundry.local/site_config.json
# 5. Run `bench setup` or your preferred deployment method
# 6. Test the deployment
# 7. Configure environment-specific settings for production

# ====================================================================
# REQUIRED FOLDERS AND FILES FOR DEPLOYMENT
# ====================================================================

# --- SOURCE CODE (CORE FRAMEWORKS) ---
site
  apps/frappe/           # Frappe framework source code
  apps/erpnext/          # ERPNext framework source code
  apps/foundry_erp/      # Custom Foundry ERP application

# --- CONFIGURATION FILES ---
site
  config/               # Global configuration files (redis, scheduler, etc.)
  sites/                # Site-specific configuration

# --- DEPLOYMENT FILES ---
site
  Procfile              # Process management file
  package.json          # Node.js dependency configuration
  pyproject.toml        # Python dependency configuration
  README.md             # Documentation and deployment instructions
  DEPLOYMENT_CHECKLIST.md # Deployment preparation checklist
  .gitignore            # GitHub-specific ignore file
  cleanup.sh            # Cleanup script for future maintenance

# --- ESSENTIAL SITE STRUCTURE ---
site
  sites/
    foundry.local/     # Frappe site directory (modify site name as needed)
    private/          # Contains: backups, private files
    public/           # Contains: public assets, files

# --- LOG AND DATA STORAGE (TO BE CONFIGURED) ---
site
  # Logs can be redirected to external storage or cloud services in production
  # Use Docker volumes or managed logging services for production deployments

# --- ENVIRONMENT VARIABLES FOR PRODUCTION ---
site
  # Set these in deployment scripts or .env files:
  # DB_HOST, DB_NAME, DB_USER, DB_PASSWORD
  # REDIS_HOST, REDIS_PORT
  # BENCHMARK_CONFIG, etc.

# ====================================================================
# TEAMWORKFLOW AND COLLABORATION BEST PRACTICES
# ====================================================================

# --- FOR DEVELOPER TEAM ---
# 1. Each developer should have their own site with:
#    - Separate database
#    - Separate site directory
#    - Custom configuration
# 2. Use feature branches for new development
# 3. Follow pull request review process
# 4. Use git tags for releases

# --- FOR DEPLOYMENT TEAM ---
# 1. Use staging environment for final testing
# 2. Automated deployment scripts for production
# 3. Rollback plan for emergency situations
# 4. Monitoring and alerting setup

# --- FOR SECURITY TEAM ---
# 1. Rotate all secrets before production deployment
# 2. Use vault or secret management services
# 3. Regular security audits
# 4. Access control management

# ====================================================================
# BACKUP AND DISASTER RECOVERY
# ====================================================================

# Recommended backup strategy:
# 1. Database backups: Use mysqldump or equivalent
# 2. Site data: Backup sites/foundry.local directory
# 3. Configuration files: Backup config/ directory
# 4. Site-specific customizations: Document any modifications
# 5. Test restore procedures regularly
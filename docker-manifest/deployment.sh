# deployment script for Infrastructure as Code (IaC)
# Version 1.0
# Compatible with Frappe 15.x + ERPNext + Foundry ERP

# Environment Configuration
export PYTHONUNBUFFERED=1
export DJANGO_SETTINGS_MODULE=frappe.core.default_settings
export PORT=8000

# Application Configuration
APP_NAME="Saradata ERP Deploy"
APP_VERSION="1.0.0"
FRAMEWORK="Frappe 15.x + ERPNext + Foundry ERP"

# Deployment Settings
export RAILWAY_ENVIRONMENT=production
export RAILWAY_DEPLOYMENT=production

# Database Configuration (to be set via environment variables)
# export DATABASE_URL=postgresql://user:password@host:5432/db
# export REDIS_URL=redis://host:6379

# Performance Settings
export BENCHMARK_MODE=false
export LOG_LEVEL=INFO

# Security Settings
export ALLOWED_HOSTS=*.railway.app
export CSRF_TRUSTED_ORIGINS=https://*.railway.app

# Application Directories
APP_ROOT="."
SITES_DIR="sites/foundry.local"
LOGS_DIR="logs"
BACKUP_DIR="$SITES_DIR/backups"

# Application initialization function
init_app() {
    log "Initializing Frappe application..."
    
    # Create necessary directories
    mkdir -p "$LOGS_DIR"
    mkdir -p "$SITES_DIR/private/files"
    mkdir -p "$SITES_DIR/public/files"
    mkdir -p "$BACKUP_DIR"
    mkdir -p "$SITES_DIR/pending"
    
    # Check if Frappe site exists
    if [ ! -f "$SITES_DIR/.site_config.json" ]; then
        log "Creating new Frappe site: foundry.local"
        bench setup create-site foundry.local
    else
        log "Frappe site already exists, skipping initialization"
    fi
    
    # Load site configuration
    if [ -f "$SITES_DIR/site_config.json" ]; then
        log "Site configuration loaded"
    else
        log "Warning: No site configuration found"
    fi
}

# Function to check application health
check_health() {
    local health_status=0
    
    # Check Python version
    if ! python3 --version > /dev/null 2>&1; then
        error_log "Python 3 is required but not installed"
        return 1
    fi
    
    # Check Node.js version
    if ! command -v node >/dev/null 2>&1; then
        warn "Node.js not found. Application may have limited functionality."
    fi
    
    # Check Frappe framework
    if ! python3 -c "import frappe" 2>/dev/null; then
        error_log "Frappe framework not found"
        return 1
    fi
    
    # Check database connection
    if [ -n "$DATABASE_URL" ]; then
        log "Database configuration found"
    else
        warn "No database configuration found"
    fi
    
    log "Application health check completed"
    return $health_status
}

# Function to log errors
error_log() {
    echo "[ERROR] $(date '+%Y-%m-%d %H:%M:%S') $*" >&2
}

# Function to log warnings
warn() {
    echo "[WARNING] $(date '+%Y-%m-%d %H:%M:%S') $*" >&2
}

# Main application startup
main() {
    log "Starting $APP_NAME version $APP_VERSION"
    log "Framework: $FRAMEWORK"
    log "Environment: $RAILWAY_ENVIRONMENT"
    
    # Initialize application
    init_app
    
    # Check application health
    check_health
    
    # Start the application
    log "Starting Frappe server..."
    log "Application is ready to accept connections"
    
    exec honcho start -f Procfile
}

# Execute main function
main

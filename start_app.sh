#!/bin/bash

set -e

log() {
    echo -e "[$(date '+%Y-%m-%d %H:%M:%S')] $*"
}

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

error_log() {
    echo -e "\$RED[\$(date '+%Y-%m-%d %H:%M:%S')] ERROR:\$NC \$1" >&2
}

warn() {
    echo -e "\$YELLOW[\$(date '+%Y-%m-%d %H:%M:%S')] WARNING:\$NC \$1" >&2
}

log() {
    echo -e "\$GREEN[\$(date '+%Y-%m-%d %H:%M:%S')]\$NC \$1"
}

# Default configuration
export PYTHONUNBUFFERED=1
export DJANGO_SETTINGS_MODULE=frappe.core.default_settings
export PORT=8000
export NODE_ENV=production

# Check Python version
log "Checking Python version..."
if ! command -v python3 > /dev/null 2>&1; then
    error_log "Python 3 is required but not installed"
    exit 1
fi

# Check Frappe version
log "Checking Frappe version..."
if [ -f "apps/frappe/frappe/version/__init__.py" ]; then
    source apps/frappe/frappe/version/__init__.py
    log "Frappe version: $VERSION"
else
    warn "Frappe version file not found"
fi

# Check ERPNext version
log "Checking ERPNext version..."
if [ -f "apps/erpnext/version.txt" ]; then
    ERPNEXT_VERSION=$(cat apps/erpnext/version.txt)
    log "ERPNext version: $ERPNEXT_VERSION"
else
    warn "ERPNext version file not found"
fi

# Check Node.js version
log "Checking Node.js version..."
if ! command -v node >/dev/null 2>&1; then
    error_log "Node.js is required but not installed"
    exit 1
fi

# Create Procfile if it doesn't exist
if [ ! -f "Procfile" ]; then
    log "Creating Procfile for process management..."
    cat > Procfile << EOF
web: python -m frappe --host 0.0.0.0 --port \$PORT
worker: frappe
EOF
fi

# Initialize Frappe site if not exists
if [ ! -f "sites/foundry.local/.site_config.json" ]; then
    log "Initializing Frappe site..."
    bench setup create-site foundry.local
else
    log "Frappe site already configured"
fi

log "Starting Frappe server..."
log "Procfile content:"
cat Procfile
exec honcho start -f Procfile

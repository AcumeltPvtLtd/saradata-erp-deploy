#!/bin/bash

set -e

# Simple and clean startup script
log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') $*"
}

# Default configuration
export PYTHONUNBUFFERED=1
export DJANGO_SETTINGS_MODULE=frappe.core.default_settings
export PORT=8000

# Check essential source code
if [ ! -d "apps/frappe/frappe" ]; then
    echo "ERROR: Frappe source code not found"
    exit 1
fi
if [ ! -d "apps/erpnext/erpnext" ]; then
    echo "ERROR: ERPNext source code not found"  
    exit 1
fi

# Create Procfile
if [ ! -f "Procfile" ]; then
    cat > Procfile << EOF
web: python -m frappe --host 0.0.0.0 --port $PORT
worker: frappe
EOF
fi

# Initialize Frappe site
if [ ! -f "sites/foundry.local/.site_config.json" ]; then
    log "Initializing Frappe site..."
    bench setup create-site foundry.local
fi

log "Starting Frappe server..."
exec honcho start -f Procfile

#!/bin/bash

set -e

log() {
    echo -e "[$(date '+%Y-%m-%d %H:%M:%S')] $*"
}

data_dir() { echo "sites/foundry.local" }

# Initialize Frappe site if not exists
if [ ! -f "$(data_dir)/.site_config.json" ]; then
    log "Initializing Frappe site..."
    bench setup create-site foundry.local
fi

# Start the application
log "Starting Frappe server on port $PORT..."
log "Procfile structure:" && cat Procfile
exec honcho start -f Procfile

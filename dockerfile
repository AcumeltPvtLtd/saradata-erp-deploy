# Frappe Bench Production Dockerfile for Railway
# Version: 15.0
# RAILWAY-OPTIMIZED - Builds cleanly on python:3.12-slim (Debian trixie)

FROM python:3.12-slim

# Install only system packages available in Debian trixie (python:3.12-slim)
RUN apt-get update && apt-get install -y --no-install-recommends \
    curl \
    gnupg \
    git \
    wget \
    unzip \
    nodejs \
    npm \
    ca-certificates \
    build-essential \
    libpango-1.0-0 \
    libpangoft2-1.0-0 \
    libpangocairo-1.0-0 \
    libcairo2 \
    libgdk-pixbuf-2.0-0 \
    libffi8 \
    shared-mime-info \
    fonts-dejavu-core \
    && rm -rf /var/lib/apt/lists/*

# Set working directory
WORKDIR /app

# Copy full app source trees (keeps repo layout; enables editable installs)
COPY apps/frappe/ ./apps/frappe/
COPY apps/erpnext/ ./apps/erpnext/
COPY apps/foundry_erp/ ./apps/foundry_erp/

# Official Bench application layout: each app package is importable from the
# apps directory (editable installs link to this source tree, not an isolated copy)
ENV PYTHONPATH=/app/apps/frappe:/app/apps/erpnext

# Install Python dependencies (editable installs of each Frappe app, as bench does)
RUN pip install --no-cache-dir --upgrade pip \
    && pip install --no-cache-dir -e ./apps/frappe \
    && pip install --no-cache-dir -e ./apps/erpnext \
    && pip install --no-cache-dir honcho

# Gate the build: verify the Frappe/ERPNext imports resolve to the app source
RUN python -c "import frappe; import frappe.utils.typing_validations; import erpnext; print('Apps import OK: frappe', frappe.__version__, '| erpnext', erpnext.__version__)"

# Copy configuration files
COPY config/ ./config/

# Create necessary directories (bench layout: logs + sites for runtime)
RUN mkdir -p logs sites

# Set up non-root user for security (password locked by default)
RUN useradd -r -M -d /app -s /bin/sh appuser \
    && chown -R appuser:appuser /app

# Environment variables
ENV PYTHONUNBUFFERED=1
ENV PYTHONPATH=/app/apps/frappe:/app/apps/erpnext
ENV PORT=8000
ENV NODE_ENV=production

EXPOSE 8000

# Start script (PORT expands at runtime, not build time)
RUN cat > /app/start.sh <<'EOS'
#!/bin/sh
set -e
export PORT="${PORT:-8000}"
exec gunicorn frappe.app:application --bind "0.0.0.0:${PORT}" --workers 2 --timeout 120
EOS
RUN chmod +x /app/start.sh

# Create Procfile for Honcho (process manager)
RUN printf 'web: /app/start.sh\n' > Procfile

USER appuser

CMD ["honcho", "start", "-f", "Procfile"]

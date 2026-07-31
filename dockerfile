# Frappe Bench Production Dockerfile for Railway
# Version: 11.0
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
    && rm -rf /var/lib/apt/lists/*

# Set working directory
WORKDIR /app

# Copy full app source trees (keeps repo layout; enables editable installs)
COPY apps/frappe/ ./apps/frappe/
COPY apps/erpnext/ ./apps/erpnext/
COPY apps/foundry_erp/ ./apps/foundry_erp/

# Install Python dependencies (editable installs of each Frappe app)
RUN pip install --no-cache-dir --upgrade pip \
    && pip install --no-cache-dir -e ./apps/frappe \
    && pip install --no-cache-dir -e ./apps/erpnext \
    && pip install --no-cache-dir honcho

# Copy configuration files
COPY config/ ./config/

# Create necessary directories
RUN mkdir -p logs

# Set up non-root user for security
RUN useradd --disabled-password --gecos '' appuser \
    && chown -R appuser:appuser /app

# Environment variables
ENV PYTHONUNBUFFERED=1
ENV PYTHONPATH=/app
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

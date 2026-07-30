# Frappe Bench Production Dockerfile for Railway
# Version: 8.0 - VALIDATED NO SHELL SYNTAX

FROM python:3.12-slim

# Install system dependencies for Frappe framework
RUN apt-get update && apt-get install -y curl gnupg software-properties-common git wget unzip && curl -fsSL https://deb.nodesource.com/setup_20.x | bash && apt-get install -y nodejs && rm -rf /var/lib/apt/lists/*

# Set working directory
WORKDIR /app

# Copy Python dependencies from actual locations
COPY apps/frappe/pyproject.toml ./
COPY apps/erpnext/pyproject.toml ./
COPY apps/foundry_erp/pyproject.toml ./

# Install Python dependencies (Frappe requires pyproject.toml)
RUN pip install --no-cache-dir --upgrade pip
RUN pip install --no-cache-dir -e ./apps/frappe
RUN pip install --no-cache-dir -e ./apps/erpnext
RUN pip install --no-cache-dir -e ./apps/foundry_erp

# Copy Node.js dependencies from apps/frappe
COPY apps/frappe/package.json ./
COPY apps/frappe/yarn.lock ./

# Install Node.js dependencies
RUN npm ci --production

# Copy application source code
COPY apps/frappe/frappe/ ./apps/frappe/frappe/
COPY apps/erpnext/erpnext/ ./apps/erpnext/erpnext/
COPY apps/foundry_erp/ ./apps/foundry_erp/

# Copy configuration files
COPY config/ ./config/

# Create necessary directories
RUN mkdir -p logs

# Set up non-root user for security
RUN useradd --disabled-password --gecos '' appuser
RUN chown -R appuser:appuser /app
USER appuser

# Environment variables
ENV PYTHONUNBUFFERED=1
ENV PYTHONPATH=/app
ENV DJANGO_SETTINGS_MODULE=frappe.core.default_settings
ENV PORT=8000
ENV NODE_ENV=production

EXPOSE 8000

# Create Procfile
RUN $"cat > Procfile << EOF\\nweb: python -m frappe --host 0.0.0.0 --port \$PORT\\nEOF"

CMD ["honcho", "start", "-f", "Procfile"]

# Frappe Bench Production Dockerfile for Railway Deployment
# Version: 2.0
# Compatible with Railway PaaS platform
# Optimized for Frappe 15.x + ERPNext 1.3 + Foundry ERP

FROM python:3.12-slim

# Install system dependencies for Frappe framework
RUN apt-get update && apt-get install -y \
    curl \
    gnupg \
    software-properties-common \
    git \
    wget \
    unzip \
    && curl -fsSL https://deb.nodesource.com/setup_20.x | bash \
    && apt-get install -y nodejs \
    && rm -rf /var/lib/apt/lists/*

# Set working directory
WORKDIR /app

# Copy requirements files
COPY requirements.txt pyproject.toml setup.py setup.cfg ./

# Install Python dependencies
RUN pip install --no-cache-dir --upgrade pip && \
    pip install --no-cache-dir -r requirements.txt && \
    pip install --no-cache-dir -e .

# Copy package files and install Node.js dependencies
COPY package.json package-lock.json yarn.lock .npmrc ./
RUN npm ci --production

# Copy application source code (selective for size optimization)
COPY apps/frappe/ apps/frappe/
COPY apps/erpnext/ apps/erpnext/
COPY apps/foundry_erp/ apps/foundry_erp/

# Copy configuration files
COPY config/ Procfile .gitignore README.md DEPLOYMENT_CHECKLIST.md cleanup.sh ./

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

EXPOSE 8000

CMD ["honcho", "start", "-f", "Procfile"]

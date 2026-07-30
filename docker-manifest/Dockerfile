# Frappe Bench Production Dockerfile for Railway Deployment
# Version: 1.0
# Compatible with Railway PaaS platform
# Optimized for Frappe 15.x + ERPNext + Foundry ERP

FROM python:3.12-slim AS builder

# Install build dependencies
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

# Copy requirements and install Python dependencies
COPY requirements.txt pyproject.toml setup.py setup.cfg ./
RUN pip install --no-cache-dir --upgrade pip && \
    pip install --no-cache-dir -r requirements.txt && \
    pip install --no-cache-dir -e .

# Copy Node.js dependencies
COPY package.json package-lock.json yarn.lock .npmrc ./
RUN npm ci --prefer-offline --no-audit

# Copy source code
COPY apps/ apps/

# Create application directories
RUN mkdir -p logs

# Set up user for security
RUN useradd --disabled-password --gecos '' appuser
RUN chown -R appuser:appuser /app
USER appuser

# Environment variables
ENV PYTHONUNBUFFERED=1
ENV PYTHONPATH=/app
ENV DJANGO_SETTINGS_MODULE=frappe.core.default_settings
ENV PORT=8000

EXPOSE 8000

FROM builder AS runtime
COPY --from=builder /app /app
WORKDIR /app

CMD ["honcho", "start", "-f", "Procfile"]

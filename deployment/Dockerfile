# Frappe Bench Production Dockerfile for Railway
# Version: 3.0
# RAILWAY-OPTIMIZED FOR FRAPPE B15 + ERPNext
# Based on actual repository structure

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

# Copy Python dependencies from actual locations
COPY apps/frappe/pyproject.toml apps/erpnext/pyproject.toml apps/foundry_erp/pyproject.toml ./

# Install Python dependencies (Frappe requires pyproject.toml, not requirements.txt)
RUN pip install --no-cache-dir --upgrade pip && \
    pip install --no-cache-dir -e ./apps/frappe && \
    pip install --no-cache-dir -e ./apps/erpnext && \
    pip install --no-cache-dir -e ./apps/foundry_erp

# Copy Node.js dependencies from apps/frappe (Frappe's package.json)
COPY apps/frappe/package.json apps/frappe/yarn.lock ./

# Install Node.js dependencies
RUN npm ci --production

# Copy application source code (selective for size optimization)
COPY apps/frappe/frappe/ apps/frappe/frappe/
COPY apps/frappe/esbuild/ apps/frappe/esbuild/ 2>/dev/null || true
COPY apps/erpnext/erpnext/ apps/erpnext/erpnext/
COPY apps/foundry_erp/ apps/foundry_erp/ 2>/dev/null || true

# Copy configuration files from config/
COPY config/ ./config/

# Copy critical files that exist in repository
COPY apps/frappe/.coveragerc ./ 2>/dev/null || true
COPY apps/frappe/.editorconfig ./ 2>/dev/null || true
COPY apps/frappe/.eslintignore ./ 2>/dev/null || true
COPY apps/frappe/.eslintrc ./ 2>/dev/null || true
COPY apps/frappe/.greptile/ ./ 2>/dev/null || true
COPY apps/frappe/.mergify.yml ./ 2>/dev/null || true
COPY apps/frappe/.pre-commit-config.yaml ./ 2>/dev/null || true
COPY apps/frappe/.releaserc ./ 2>/dev/null || true
COPY apps/frappe/.semgrepignore ./ 2>/dev/null || true
COPY apps/frappe/attributions.md ./ 2>/dev/null || true
COPY apps/frappe/babel_extractors.csv ./ 2>/dev/null || true
COPY apps/frappe/codecov.yml ./ 2>/dev/null || true
COPY apps/frappe/CODEOWNERS ./ 2>/dev/null || true
COPY apps/frappe/commitlint.config.js ./ 2>/dev/null || true
COPY apps/frappe/crowdin.yml ./ 2>/dev/null || true
COPY apps/frappe/cypress.config.js ./ 2>/dev/null || true
COPY apps/frappe/generate_bootstrap_theme.js ./ 2>/dev/null || true
COPY apps/frappe/hooks.md ./ 2>/dev/null || true
COPY apps/frappe/LICENSE ./ 2>/dev/null || true
COPY apps/frappe/node_utils.js ./ 2>/dev/null || true
COPY apps/frappe/pyproject.toml ./ 2>/dev/null || true
COPY apps/frappe/README.md ./ 2>/dev/null || true
COPY apps/frappe/realtime/ ./ 2>/dev/null || true
COPY apps/frappe/SECURITY.md ./ 2>/dev/null || true
COPY apps/frappe/sider.yml ./ 2>/dev/null || true
COPY apps/frappe/socketio.js ./ 2>/dev/null || true
COPY apps/frappe/yarn.lock ./ 2>/dev/null || true

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

# Create Procfile for Honcho (process manager)
RUN echo 'web: python -m frappe --host 0.0.0.0 --port $PORT\n' > Procfile

CMD ["honcho", "start", "-f", "Procfile"]

# Official Frappe Bench architecture for Railway
# Version: 16.1
# Rebuilt from the source-tree-only image into a real bench: frappe-bench CLI,
# apps/ layout with editable installs, sites/apps.txt, production asset build,
# and runtime bootstrapping (site creation / migration / app installs).
#
# Runtime flow (deployment/entrypoint.sh):
#   bench new-site -> bench install-app erpnext foundry_erp -> bench migrate
#   -> gunicorn frappe.app:application on $PORT

FROM python:3.12-slim

# ---- system dependencies (Debian trixie) ----
RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates \
    curl \
    wget \
    git \
    unzip \
    build-essential \
    nodejs \
    npm \
    libpango-1.0-0 \
    libpangoft2-1.0-0 \
    libpangocairo-1.0-0 \
    libcairo2 \
    libgdk-pixbuf-2.0-0 \
    libffi8 \
    shared-mime-info \
    fonts-dejavu-core \
    && rm -rf /var/lib/apt/lists/*

# yarn 1.x — frappe's frontend asset build
RUN npm install --no-audit --no-fund --global yarn

# ---- bench user (official frappe_docker layout) ----
RUN useradd -r -m -d /home/frappe -s /bin/bash frappe

WORKDIR /home/frappe/frappe-bench

# ---- bench virtualenv + frappe-bench CLI ----
RUN python -m venv env \
    && env/bin/pip install --no-cache-dir --upgrade pip \
    && env/bin/pip install --no-cache-dir "frappe-bench~=5.31"

# ---- app source trees (official bench apps/ layout) ----
COPY apps/frappe ./apps/frappe
COPY apps/erpnext ./apps/erpnext
COPY apps/foundry_erp ./apps/foundry_erp

# ---- install apps editable into the bench env (as `bench get-app` does) ----
RUN env/bin/pip install --no-cache-dir \
        -e ./apps/frappe \
        -e ./apps/erpnext \
        -e ./apps/foundry_erp \
    && env/bin/python -c "import frappe; import frappe.utils.typing_validations; import erpnext; import foundry_erp; print('Apps import OK: frappe', frappe.__version__, '| erpnext', erpnext.__version__, '| foundry_erp', foundry_erp.__version__)"

# ---- bench metadata (apps.txt is the bench root marker + app list) ----
RUN mkdir -p sites logs config config/pids
COPY sites/apps.txt sites/apps.txt
COPY config/ config/

# ---- frontend dependencies + production asset build.
#      Runs as the frappe user (bench refuses privileged commands when root
#      unless a `frappe_user` is configured in common_site_config.json). ----
RUN chown -R frappe:frappe /home/frappe/frappe-bench

ENV HOME=/home/frappe
ENV SITES_PATH=/home/frappe/frappe-bench/sites
ENV PYTHONUNBUFFERED=1
ENV NODE_ENV=production
ENV PORT=8000
ENV PATH=/home/frappe/frappe-bench/env/bin:$PATH

USER frappe

RUN cd apps/frappe && yarn install --frozen-lockfile
RUN cd apps/erpnext && yarn install --frozen-lockfile
RUN FRAPPE_DOCKER_BUILD=1 bench build --apps frappe,erpnext,foundry_erp --production --verbose \
    && test -d sites/assets/frappe/dist/js \
    && echo "Assets built OK"

# ---- entrypoint (bench bootstrap + serve) ----
USER root
COPY deployment/entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh && chown frappe:frappe /entrypoint.sh

USER frappe
WORKDIR /home/frappe/frappe-bench

EXPOSE 8000

CMD ["/entrypoint.sh"]

#!/usr/bin/env bash
set -euo pipefail

BENCH_ROOT="/home/frappe/frappe-bench"
SITES_PATH="$BENCH_ROOT/sites"

export HOME="/home/frappe"
export PATH="$BENCH_ROOT/env/bin:$PATH"
export SITES_PATH
export PYTHONUNBUFFERED=1

cd "$BENCH_ROOT"

# bench CLI requires apps/ sites/ config/ logs/ config/pids at the bench root
mkdir -p sites logs config config/pids

# MySQL/MariaDB client: never verify Railway's self-signed TLS certificate
# (frappe shells out to the mariadb CLI during `bench new-site` schema restore).
mkdir -p "$HOME"
printf '[client]\nssl=0\nssl-verify-server-cert=0\n' > "$HOME/.my.cnf"
chmod 600 "$HOME/.my.cnf"

log() { echo "[entrypoint] $(date -u +%FT%TZ) $*"; }

# ---- resolve configuration from Railway environment ----
SITE_NAME="${SITE_NAME:-${RAILWAY_PUBLIC_DOMAIN:-foundry.local}}"
DB_TYPE="${DB_TYPE:-mariadb}"
ADMIN_PASSWORD="${ADMIN_PASSWORD:-admin}"
PORT="${PORT:-8000}"
WEB_WORKERS="${WEB_WORKERS:-2}"
WEB_TIMEOUT="${WEB_TIMEOUT:-120}"

# percent-decode URL components (%20, %40, ...)
urldecode() {
    local data="${*//+/ }"
    printf '%b' "${data//%/\\x}"
}

# parse Railway's mysql://USER:PASSWORD@HOST:PORT/DATABASE (also accepted via
# DATABASE_URL). Sets DB_HOST/DB_PORT/DB_NAME/DB_USER/DB_PASSWORD.
parse_mysql_url() {
    local url="$1" rest userinfo hostport user pw host port db
    rest="${url#*://}"
    userinfo="${rest%@*}"
    hostport="${rest##*@}"
    [ "$hostport" = "$rest" ] && return 1
    user="${userinfo%%:*}"
    pw="${userinfo#*:}"
    db="${hostport#*/}"
    db="${db%%\?*}"
    hostport="${hostport%%/*}"
    case "$hostport" in
        *:*) host="${hostport%%:*}"; port="${hostport#*:}" ;;
        *) host="$hostport"; port="3306" ;;
    esac
    [ -n "$user" ] && DB_USER="$(urldecode "$user")"
    [ -n "$pw" ] && DB_PASSWORD="$(urldecode "$pw")"
    [ -n "$host" ] && DB_HOST="$(urldecode "$host")"
    [ -n "$port" ] && DB_PORT="$(urldecode "$port")"
    [ -n "$db" ] && DB_NAME="$(urldecode "$db")"
    return 0
}

DB_HOST=""
DB_PORT=""
DB_NAME=""
DB_USER=""
DB_PASSWORD=""

MYSQL_URL="${MYSQL_URL:-${DATABASE_URL:-}}"
if [ -n "$MYSQL_URL" ]; then
    if parse_mysql_url "$MYSQL_URL"; then
        log "resolved database credentials from MYSQL_URL/DATABASE_URL"
    else
        log "WARN: MYSQL_URL/DATABASE_URL present but unparsable; falling back to individual variables"
    fi
fi

# Individual variables override/complete the URL (supports the Railway MySQL
# plugin aliases MYSQLHOST/MYSQLPORT/MYSQLDATABASE/MYSQLUSER/MYSQLPASSWORD).
DB_HOST="${DB_HOST:-${MYSQL_HOST:-${MYSQLHOST:-127.0.0.1}}}"
DB_PORT="${DB_PORT:-${MYSQL_PORT:-${MYSQLPORT:-3306}}}"
DB_NAME="${DB_NAME:-${MYSQL_DATABASE:-${MYSQLDATABASE:-}}}"
DB_USER="${DB_USER:-${MYSQL_USER:-${MYSQLUSER:-}}}"
DB_PASSWORD="${DB_PASSWORD:-${MYSQL_PASSWORD:-${MYSQLPASSWORD:-}}}"

if [ -z "$DB_NAME" ] || [ -z "$DB_USER" ] || [ -z "$DB_PASSWORD" ]; then
    log "ERROR: DB_NAME, DB_USER and DB_PASSWORD are required (attach the Railway MySQL service and set these variables)."
    exit 1
fi

masked() {
    if [ -n "$1" ]; then
        echo "**** (len=${#1})"
    else
        echo "(unset)"
    fi
}

mask_redis() {
    case "$1" in
        redis://*@*) echo "redis://***@${1#*@}" ;;
        *) echo "$1" ;;
    esac
}

REDIS_URL="${REDIS_URL:-${RAILWAY_REDIS_URL:-}}"
if [ -z "$REDIS_URL" ]; then
    REDIS_HOST="${REDIS_HOST:-${REDIS_HOSTNAME:-}}"
    REDIS_PORT="${REDIS_PORT:-6379}"
    REDIS_PASSWORD="${REDIS_PASSWORD:-}"
    if [ -z "$REDIS_HOST" ]; then
        log "ERROR: REDIS_URL or REDIS_HOST is required (attach the Railway Redis service)."
        exit 1
    fi
    if [ -n "$REDIS_PASSWORD" ]; then
        REDIS_URL="redis://:${REDIS_PASSWORD}@${REDIS_HOST}:${REDIS_PORT}"
    else
        REDIS_URL="redis://${REDIS_HOST}:${REDIS_PORT}"
    fi
fi

log "site=${SITE_NAME} db_host=${DB_HOST}:${DB_PORT} db_name=${DB_NAME} db_user=${DB_USER} db_password=$(masked "$DB_PASSWORD") redis=$(mask_redis "$REDIS_URL")"

# ---- common site config (redis / production settings) ----
mkdir -p "$SITES_PATH"
cat > "$SITES_PATH/common_site_config.json" <<EOF
{
    "developer_mode": 0,
    "maintenance_mode": 0,
    "auto_update": 0,
    "allow_tests": 0,
    "webserver_port": ${PORT},
    "restart_supervisor_on_update": 0,
    "redis_cache": "${REDIS_URL}",
    "redis_queue": "${REDIS_URL}",
    "redis_socketio": "${REDIS_URL}"
}
EOF

# ---- site config (database). Written before `bench new-site` so make_conf
#      preserves db_user (Railway's pre-created MySQL user). ----
mkdir -p "$SITES_PATH/$SITE_NAME"
cat > "$SITES_PATH/$SITE_NAME/site_config.json" <<EOF
{
    "db_type": "${DB_TYPE}",
    "db_host": "${DB_HOST}",
    "db_port": ${DB_PORT},
    "db_name": "${DB_NAME}",
    "db_user": "${DB_USER}",
    "db_password": "${DB_PASSWORD}"
}
EOF

# ---- is the database already initialized with a frappe schema? ----
db_initialized() {
    "$BENCH_ROOT/env/bin/python" - "$DB_HOST" "$DB_PORT" "$DB_USER" "$DB_PASSWORD" "$DB_NAME" <<'PYEOF'
import sys

import pymysql

host, port, user, password, db = sys.argv[1:6]
try:
    conn = pymysql.connect(
        host=host, port=int(port), user=user, password=password, connect_timeout=15
    )
    with conn.cursor() as cur:
        cur.execute(
            "SELECT COUNT(*) FROM information_schema.tables "
            "WHERE table_schema=%s AND table_name='tabDocType'",
            (db,),
        )
        row = cur.fetchone()
    conn.close()
    print(row[0] if row else 0)
except Exception as exc:
    print(
        f"db-probe: connection failed for user={user} host={host}:{port} db={db}: {exc}",
        file=sys.stderr,
    )
    print(0)
PYEOF
}

INITIALIZED="$(db_initialized)"

if [ "$INITIALIZED" != "0" ]; then
    log "database already initialized (${INITIALIZED} frappe table(s)) -> ensuring apps are installed"
    bench --site "$SITE_NAME" install-app erpnext foundry_erp \
        || log "WARN: install-app reported errors (apps may already be installed); continuing"
    log "running migrations"
    bench --site "$SITE_NAME" migrate --skip-failing
else
    log "fresh database -> creating site ${SITE_NAME}"
    bench new-site "$SITE_NAME" \
        --no-setup-db \
        --db-name "$DB_NAME" \
        --db-password "$DB_PASSWORD" \
        --db-host "$DB_HOST" \
        --db-port "$DB_PORT" \
        --admin-password "$ADMIN_PASSWORD" \
        --install-app erpnext \
        --install-app foundry_erp \
        --force
    log "site created; running migrations"
    bench --site "$SITE_NAME" migrate --skip-failing
fi

log "installed apps:"
bench --site "$SITE_NAME" list-apps || true

log "starting gunicorn on 0.0.0.0:${PORT}"
cd "$SITES_PATH"
exec gunicorn frappe.app:application \
    --bind "0.0.0.0:${PORT}" \
    --workers "${WEB_WORKERS}" \
    --timeout "${WEB_TIMEOUT}" \
    --access-logfile - \
    --error-logfile -

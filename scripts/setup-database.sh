
#!/usr/bin/env bash
set -euo pipefail
umask 077

if [[ "$EUID" -ne 0 ]]; then
  echo "Run with sudo."
  exit 1
fi

INIT_SQL="${1:-}"
if [[ -z "$INIT_SQL" || ! -f "$INIT_SQL" ]]; then
  echo "Usage: sudo bash setup-database.sh /path/to/init.sql"
  exit 1
fi

ENV_FILE=/etc/task-tracker.env
DB_NAME=task_tracker
DB_USER=task_tracker_app

apt-get update
apt-get install -y postgresql postgresql-client openssl
systemctl enable --now postgresql

# Reuse the existing password where possible.
DB_PASSWORD=""
if [[ -f "$ENV_FILE" ]]; then
  DB_PASSWORD="$(sed -n 's/^DB_PASSWORD=//p' "$ENV_FILE" | head -n 1)"
fi

if [[ -z "$DB_PASSWORD" ]]; then
  DB_PASSWORD="$(openssl rand -hex 32)"
  SET_PASSWORD=true
else
  SET_PASSWORD=false
fi

# Create the database role if missing.
if ! runuser -u postgres -- psql -tAc \
  "SELECT 1 FROM pg_roles WHERE rolname='$DB_USER'" | grep -q 1; then
  runuser -u postgres -- psql -v ON_ERROR_STOP=1 \
    -c "CREATE ROLE $DB_USER LOGIN"
  SET_PASSWORD=true
fi

# Set a password only when creating or recovering the role configuration.
if [[ "$SET_PASSWORD" == true ]]; then
  runuser -u postgres -- psql -v ON_ERROR_STOP=1 \
    -v db_password="$DB_PASSWORD" <<'SQL'
ALTER ROLE task_tracker_app WITH LOGIN PASSWORD :'db_password';
SQL
fi

# Create the database only if it doesn't exist.
if ! runuser -u postgres -- psql -tAc \
  "SELECT 1 FROM pg_database WHERE datname='$DB_NAME'" | grep -q 1; then
  runuser -u postgres -- createdb -O "$DB_USER" "$DB_NAME"
fi

# Write application database configuration.
printf 'PORT=3000\nDB_HOST=127.0.0.1\nDB_PORT=5432\nDB_DATABASE=%s\nDB_USER=%s\nDB_PASSWORD=%s\n' \
  "$DB_NAME" "$DB_USER" "$DB_PASSWORD" > "$ENV_FILE"

chown root:root "$ENV_FILE"
chmod 600 "$ENV_FILE"

# Initialize schema and grant application permissions.
runuser -u postgres -- psql \
  -v ON_ERROR_STOP=1 -d "$DB_NAME" -f "$INIT_SQL"

runuser -u postgres -- psql -v ON_ERROR_STOP=1 \
  -d "$DB_NAME" <<'SQL'
GRANT CONNECT ON DATABASE task_tracker TO task_tracker_app;
GRANT USAGE ON SCHEMA public TO task_tracker_app;
GRANT SELECT, INSERT, UPDATE, DELETE
  ON ALL TABLES IN SCHEMA public TO task_tracker_app;
GRANT USAGE, SELECT
  ON ALL SEQUENCES IN SCHEMA public TO task_tracker_app;

ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA public
  GRANT SELECT, INSERT, UPDATE, DELETE ON TABLES TO task_tracker_app;
ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA public
  GRANT USAGE, SELECT ON SEQUENCES TO task_tracker_app;
SQL

echo "Database setup completed: $DB_NAME"

#!/usr/bin/env bash
set -euo pipefail

# Load .env safely (if present)
if [ -f .env ]; then
  # export variables defined in .env (handles values with spaces)
  set -a
  # shellcheck disable=SC1090
  source .env
  set +a
fi

HOST_BACKUP_DIR="${HOST_BACKUP_DIR:-$PWD/postgres_backups}"
DB_NAME="${POSTGRES_DB:-${DB_NAME:-}}"
DB_USER="${POSTGRES_USER:-${DB_USER:-postgres}}"
DB_PASSWORD="${POSTGRES_PASSWORD:-${DB_PASSWORD:-}}"
DB_HOST="${DB_HOST:-localhost}"
DB_PORT="${POSTGRES_PORT:-${DB_PORT:-5432}}"

mkdir -p "$HOST_BACKUP_DIR"

echo "Running backup job on $(date)..."

# Basic validation
if [ -z "$DB_NAME" ]; then
  echo "ERROR: DB_NAME (POSTGRES_DB) is not set."
  exit 1
fi

# Wait for Postgres to be ready
until PGPASSWORD="$DB_PASSWORD" pg_isready -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" > /dev/null 2>&1; do
  echo "Waiting for Postgres to be ready at ${DB_HOST}:${DB_PORT}..."
  sleep 2
done

# Run backup and compress output
TIMESTAMP="$(date +%Y%m%d_%H%M%S)"
SAFE_DB_NAME="${DB_NAME// /_}"
BACKUP_FILE="$HOST_BACKUP_DIR/${SAFE_DB_NAME}_${TIMESTAMP}.sql.gz"

if PGPASSWORD="$DB_PASSWORD" pg_dump -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" "$DB_NAME" | gzip > "$BACKUP_FILE"; then
  echo "Backup saved to $BACKUP_FILE"
else
  echo "ERROR: Backup failed."
  exit 1
fi

echo "Backup finished successfully."
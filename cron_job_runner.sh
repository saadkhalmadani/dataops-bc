#!/bin/bash
# Load .env
if [ -f .env ]; then
  export $(grep -v '^#' .env | xargs)
fi

HOST_BACKUP_DIR="${HOST_BACKUP_DIR:-$PWD/postgres_backups}"
DB_NAME="${POSTGRES_DB}"
DB_USER="${POSTGRES_USER}"
DB_PASSWORD="${POSTGRES_PASSWORD}"
DB_HOST="${DB_HOST:-db}"
DB_PORT="${POSTGRES_PORT}"

mkdir -p "$HOST_BACKUP_DIR"

echo "Running backup job on $(date)..."

# Wait for Postgres
until PGPASSWORD="$DB_PASSWORD" pg_isready -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" > /dev/null 2>&1; do
  echo "Waiting for Postgres to be ready..."
  sleep 2
done

# Run backup
BACKUP_FILE="$HOST_BACKUP_DIR/${DB_NAME}_$(date +%Y%m%d_%H%M%S).sql"
PGPASSWORD="$DB_PASSWORD" pg_dump -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" "$DB_NAME" > "$BACKUP_FILE"

if [ $? -eq 0 ]; then
  echo "Backup saved to $BACKUP_FILE"
else
  echo "ERROR: Backup failed."
  exit 1
fi

echo "Backup finished successfully."

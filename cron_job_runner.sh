#!/bin/bash
# cron_job_runner.sh (CI/CD safe for GitHub Actions)

# --- Configuration ---
HOST_BACKUP_DIR="${HOST_BACKUP_DIR:-$PWD/postgres_backups}"
DB_NAME="${DB_NAME:-bootcamp_db}"
DB_USER="${DB_USER:-bootcamp_admin}"
DB_PASSWORD="${DB_PASSWORD:-secure_password}"
DB_HOST="${DB_HOST:-db}"  # Service hostname in GitHub Actions
DB_PORT="${DB_PORT:-5434}"

# --- Ensure backup directory exists ---
mkdir -p "$HOST_BACKUP_DIR"

echo "Running backup job on $(date)..."

# --- Wait until Postgres is ready via TCP ---
until PGPASSWORD="$DB_PASSWORD" pg_isready -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" > /dev/null 2>&1; do
    echo "Waiting for Postgres to be ready..."
    sleep 2
done

echo "Postgres is ready. Starting backup..."

# --- Run pg_dump directly via TCP ---
BACKUP_FILE="$HOST_BACKUP_DIR/${DB_NAME}_$(date +%Y%m%d_%H%M%S).sql"
PGPASSWORD="$DB_PASSWORD" pg_dump -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" "$DB_NAME" > "$BACKUP_FILE"

if [ $? -eq 0 ]; then
    echo "Backup saved to $BACKUP_FILE"
else
    echo "ERROR: Backup failed."
    exit 1
fi

echo "Backup process finished successfully."

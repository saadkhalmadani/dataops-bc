#!/bin/bash
# cron_job_runner.sh (CI/CD safe for GitHub Actions)

# --- Configuration ---
CONTAINER_NAME="${CONTAINER_NAME:-postgres_bootcamp}"   # GitHub Actions service name
HOST_BACKUP_DIR="${HOST_BACKUP_DIR:-$PWD/postgres_backups}"
DB_NAME="${DB_NAME:-bootcamp_db}"
DB_USER="${DB_USER:-bootcamp_admin}"

# --- Ensure backup directory exists ---
mkdir -p "$HOST_BACKUP_DIR"

echo "Running backup job on $(date)..."

# --- Wait until Postgres is ready ---
until docker exec -u postgres "$CONTAINER_NAME" pg_isready -U "$DB_USER" > /dev/null 2>&1; do
    echo "Waiting for Postgres to be ready..."
    sleep 2
done

# --- Run pg_dump inside container ---
BACKUP_FILE="$HOST_BACKUP_DIR/${DB_NAME}_$(date +%Y%m%d_%H%M%S).sql"
docker exec -u postgres "$CONTAINER_NAME" pg_dump -U "$DB_USER" "$DB_NAME" > "$BACKUP_FILE"

if [ $? -eq 0 ]; then
    echo "Backup saved to $BACKUP_FILE"
else
    echo "ERROR: Backup failed inside container."
    exit 1
fi

echo "Backup process finished successfully."

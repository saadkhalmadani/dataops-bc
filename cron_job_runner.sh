#!/bin/bash
# cron_job_runner.sh (CI/CD safe for GitHub Actions)

# --- Configuration ---
CONTAINER_NAME="postgres_bootcamp"
HOST_BACKUP_DIR="${HOST_BACKUP_DIR:-$PWD/postgres_backups}"
DB_NAME="${DB_NAME:-bootcamp_db}"
DB_USER="${DB_USER:-bootcamp_admin}"

# --- Ensure backup directory exists ---
mkdir -p "$HOST_BACKUP_DIR"

# --- Check if container is running ---
if [ "$(docker ps -q -f name=$CONTAINER_NAME)" = "" ]; then
    echo "Container $CONTAINER_NAME not running. Starting temporary container..."
    docker run -d \
      --name $CONTAINER_NAME \
      -e POSTGRES_PASSWORD=postgres \
      -v pgdata:/var/lib/postgresql/data \
      postgres:17-alpine
    sleep 10
fi

echo "Running backup job on $(date)..."

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

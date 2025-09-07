#!/bin/bash
# cron_job_runner.sh (Improved)

CONTAINER_NAME="postgres_bootcamp"
HOST_BACKUP_DIR="${HOST_BACKUP_DIR:-$PWD/postgres_backups}"

# Ensure backup directory exists
mkdir -p "$HOST_BACKUP_DIR"

# Check if container exists, start if not
if [ "$(docker ps -q -f name=$CONTAINER_NAME)" = "" ]; then
  echo "Container $CONTAINER_NAME not running. Starting temporary container..."
  docker run -d --name $CONTAINER_NAME -e POSTGRES_PASSWORD=postgres postgres:15-alpine
  sleep 10
fi

echo "Running backup job on $(date)..."

# Run backup.sh inside the container
BACKUP_FILES=$(docker exec -u postgres "$CONTAINER_NAME" backup.sh)
if [ $? -ne 0 ]; then
    echo "ERROR: Backup script failed inside container. Check logs."
    exit 1
fi

# Copy each backup file to host
for FILE in $BACKUP_FILES; do
    if [ -n "$FILE" ]; then
        echo "Processing file: $FILE"
        docker cp "$CONTAINER_NAME:$FILE" "$HOST_BACKUP_DIR" && \
            echo "Copied $FILE to $HOST_BACKUP_DIR" || \
            echo "ERROR: Failed to copy $FILE"
    fi
done

echo "Backup process finished successfully."

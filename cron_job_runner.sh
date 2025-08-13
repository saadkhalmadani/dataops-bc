#!/bin/bash
# cron_job_runner.sh (Modified to handle multiple files)

# --- Configuration ---
CONTAINER_NAME="postgres_bootcamp"
HOST_BACKUP_DIR="/home/saadkh/dataops-bc/postgres_backups"

# --- Script Logic ---
# Create the host backup directory if it doesn't exist
mkdir -p "$HOST_BACKUP_DIR"

echo "Running backup job on $(date)..."

# Execute the backup script and pipe its output to a 'while read' loop.
# This loop will process each file path printed by backup.sh.
docker exec -u postgres "$CONTAINER_NAME" backup.sh | while read -r BACKUP_FILE_IN_CONTAINER; do
  if [ -n "$BACKUP_FILE_IN_CONTAINER" ]; then
    echo "Processing file from container: $BACKUP_FILE_IN_CONTAINER"
    
    # Copy the newly created backup file from the container to the host machine.
    docker cp "$CONTAINER_NAME:$BACKUP_FILE_IN_CONTAINER" "$HOST_BACKUP_DIR"
    
    if [ $? -eq 0 ]; then
      echo "Successfully copied backup to host at $HOST_BACKUP_DIR"
    else
      echo "ERROR: Failed to copy backup file from container to host."
    fi
  fi
done

# Check the exit status of the docker exec command itself
if [ ${PIPESTATUS[0]} -ne 0 ]; then
    echo "ERROR: Backup script failed inside the container. Check container logs for details."
    exit 1
fi

echo "Backup process finished successfully."
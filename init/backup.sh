#!/bin/bash
# backup.sh (Modified to create two formats)

# Exit immediately if a command fails
set -e

# --- Configuration ---
BACKUP_DIR="/var/lib/postgresql/data/backups"
# Create a common base name with a timestamp
BASE_NAME="bootcamp_db_$(date +%Y-%m-%d_%H-%M-%S)"
DUMP_FILE="$BACKUP_DIR/$BASE_NAME.dump"
SQL_FILE="$BACKUP_DIR/$BASE_NAME.sql"

# --- Script Logic ---
# Create the backup directory if it doesn't exist
mkdir -p "$BACKUP_DIR"

echo "Starting backup process..."

# Set the password for non-interactive login
export PGPASSWORD='another_secure_password'

# 1. Create the compressed .dump file (custom format)
echo "Creating .dump file..."
pg_dump -U backup_user -d bootcamp_db -F c -f "$DUMP_FILE"

# 2. Create the plain text .sql file
echo "Creating .sql file..."
pg_dump -U backup_user -d bootcamp_db -f "$SQL_FILE"

# Unset the password variable for security
unset PGPASSWORD

# IMPORTANT: Print the full path of EACH created file, one per line.
# The runner script will read these lines to copy the files out.
echo "$DUMP_FILE"
echo "$SQL_FILE"

echo "Both backup files created inside container."
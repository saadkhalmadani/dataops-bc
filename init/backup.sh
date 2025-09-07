#!/usr/bin/env bash
set -euo pipefail

# init/backup.sh - create two backup formats (.dump and .sql) and print full paths of created files
# Usage: set PGHOST, PGPORT, PGUSER, PGPASSWORD, PGDATABASE, BACKUP_DIR as env vars
# The script exits if PGPASSWORD is not set to avoid accidental credential leaks.

DEFAULT_BACKUP_DIR="${GITHUB_WORKSPACE:-/tmp}/backups"
BACKUP_DIR="${BACKUP_DIR:-$DEFAULT_BACKUP_DIR}"
TIMESTAMP="$(date +%Y-%m-%d_%H-%M-%S)"
BASE_NAME="${BASE_NAME:-bootcamp_db_$TIMESTAMP}"
DUMP_FILE="$BACKUP_DIR/$BASE_NAME.dump"
SQL_FILE="$BACKUP_DIR/$BASE_NAME.sql"

# DB defaults (can be overridden by environment variables)
PGHOST="${PGHOST:-localhost}"
PGPORT="${PGPORT:-5432}"
PGUSER="${PGUSER:-backup_user}"
PGDATABASE="${PGDATABASE:-bootcamp_db}"

mkdir -p "$BACKUP_DIR"

echo "Starting backup process..."

if [ -z "${PGPASSWORD:-}" ]; then
  echo "ERROR: PGPASSWORD is not set. Set the PGPASSWORD environment variable (use repository / Actions secrets) and retry." >&2
  exit 1
fi

# 1) Create compressed custom-format dump
echo "Creating compressed dump: $DUMP_FILE"
PGPASSWORD="$PGPASSWORD" pg_dump -h "$PGHOST" -p "$PGPORT" -U "$PGUSER" -d "$PGDATABASE" -F c -f "$DUMP_FILE"

# 2) Create plain SQL dump
echo "Creating plain SQL: $SQL_FILE"
PGPASSWORD="$PGPASSWORD" pg_dump -h "$PGHOST" -p "$PGPORT" -U "$PGUSER" -d "$PGDATABASE" -f "$SQL_FILE"

# Print the full path of each created file (one per line). The runner expects this.
echo "$DUMP_FILE"
echo "$SQL_FILE"

echo "Backup completed."
#!/usr/bin/env bash
set -euo pipefail

DEFAULT_BACKUP_DIR="./backups"
BACKUP_DIR="${BACKUP_DIR:-$DEFAULT_BACKUP_DIR}"
TIMESTAMP="$(date +%Y-%m-%d_%H-%M-%S)"
BASE_NAME="${BASE_NAME:-bootcamp_db_$TIMESTAMP}"
DUMP_FILE="$BACKUP_DIR/$BASE_NAME.dump"
SQL_FILE="$BACKUP_DIR/$BASE_NAME.sql"

# Defaults
PGHOST="${PGHOST:-db}"
PGPORT="${PGPORT:-5434}"
PGUSER="${PGUSER:-bootcamp_admin}"
PGDATABASE="${PGDATABASE:-bootcamp_db}"
PGPASSWORD="${PGPASSWORD:-secure_password}"

# Parse DATABASE_URL if provided
if [[ -n "${DATABASE_URL:-}" ]]; then
  regex='^postgres:\/\/([^:]+):([^@]+)@([^:]+):([0-9]+)\/(.+)$'
  if [[ "$DATABASE_URL" =~ $regex ]]; then
    PGUSER="${BASH_REMATCH[1]}"
    PGPASSWORD="${BASH_REMATCH[2]}"
    PGHOST="${BASH_REMATCH[3]}"
    PGPORT="${BASH_REMATCH[4]}"
    PGDATABASE="${BASH_REMATCH[5]}"
  else
    echo "❌ DATABASE_URL is invalid format: $DATABASE_URL" >&2
    exit 1
  fi
fi

mkdir -p "$BACKUP_DIR"
trap 'echo "❌ Backup failed at $(date)" >&2' ERR

echo "🚀 Starting backup for database: $PGDATABASE on $PGHOST:$PGPORT"

if [ -z "${PGPASSWORD:-}" ]; then
  echo "ERROR: PGPASSWORD is not set. Use repository/Actions secrets." >&2
  exit 1
fi

echo "📦 Creating compressed dump: $DUMP_FILE"
PGPASSWORD="$PGPASSWORD" pg_dump -h "$PGHOST" -p "$PGPORT" -U "$PGUSER" -d "$PGDATABASE" -F c -f "$DUMP_FILE"

echo "📜 Creating plain SQL: $SQL_FILE"
PGPASSWORD="$PGPASSWORD" pg_dump -h "$PGHOST" -p "$PGPORT" -U "$PGUSER" -d "$PGDATABASE" -f "$SQL_FILE"

sha256sum "$DUMP_FILE" "$SQL_FILE" > "$BACKUP_DIR/$BASE_NAME.sha256"

echo "$DUMP_FILE"
echo "$SQL_FILE"
echo "✅ Backup completed successfully at $(date)"

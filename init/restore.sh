#!/usr/bin/env bash
set -euo pipefail

: "${BACKUP_PATH:?Need to set BACKUP_PATH}"

LATEST_DUMP=$(ls -t "$BACKUP_PATH"/*.dump 2>/dev/null | head -n1)
if [[ -z "$LATEST_DUMP" ]]; then
  echo "❌ No backup file found in $BACKUP_PATH"
  exit 1
fi

LATEST_CHECKSUM="${LATEST_DUMP%.dump}.sha256"
if [[ ! -f "$LATEST_CHECKSUM" ]]; then
  echo "❌ Checksum file not found: $LATEST_CHECKSUM"
  exit 1
fi

echo "🔍 Verifying checksum for $(basename "$LATEST_DUMP")..."
sha256sum -c "$LATEST_CHECKSUM"
echo "✅ Checksum verified!"

# Parse DATABASE_URL
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

export PGPASSWORD

echo "♻️ Restoring backup: $(basename "$LATEST_DUMP")"
pg_restore --clean --if-exists --no-owner \
  -h "$PGHOST" -p "$PGPORT" -U "$PGUSER" -d "$PGDATABASE" "$LATEST_DUMP"

echo "🎉 Restore completed!"

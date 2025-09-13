#!/usr/bin/env bash
set -euo pipefail

: "${BACKUP_PATH:?Need to set BACKUP_PATH}"

# Find the latest backup (based on timestamp in filename)
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

# Verify checksum
echo "🔍 Verifying checksum for $(basename "$LATEST_DUMP")..."
sha256sum -c "$LATEST_CHECKSUM"
if [[ $? -ne 0 ]]; then
  echo "❌ Checksum mismatch! Aborting restore."
  exit 1
fi
echo "✅ Checksum verified!"

# Restore backup
echo "♻️ Restoring backup: $(basename "$LATEST_DUMP")"
pg_restore --clean --if-exists --no-owner --dbname="$DATABASE_URL" "$LATEST_DUMP"
echo "🎉 Restore completed!"

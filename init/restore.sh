#!/bin/bash
set -e

# Ensure BACKUP_PATH is set
: "${BACKUP_PATH:?Need to set BACKUP_PATH}"

# Find latest backup file
LATEST_BACKUP=$(ls -t "$BACKUP_PATH"/*.dump 2>/dev/null | head -n1)

if [[ -z "$LATEST_BACKUP" ]]; then
  echo "❌ No backup file found in $BACKUP_PATH"
  exit 1
fi

CHECKSUM_FILE="${LATEST_BACKUP}.sha256"

# Verify checksum
if [[ ! -f "$CHECKSUM_FILE" ]]; then
  echo "⚠️  Checksum file not found: $CHECKSUM_FILE"
  exit 1
fi

echo "🔍 Verifying checksum for $(basename "$LATEST_BACKUP")..."
sha256sum -c "$CHECKSUM_FILE"
if [[ $? -ne 0 ]]; then
  echo "❌ Checksum mismatch! Aborting restore."
  exit 1
fi
echo "✅ Checksum verified!"

# Restore backup
echo "♻️ Restoring backup: $(basename "$LATEST_BACKUP")"
pg_restore --clean --if-exists --no-owner --dbname="$DATABASE_URL" "$LATEST_BACKUP"
echo "🎉 Restore completed!"

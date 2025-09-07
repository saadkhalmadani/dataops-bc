#!/bin/bash
set -e

# Ensure BACKUP_PATH is set
: "${BACKUP_PATH:?Need to set BACKUP_PATH}"

# Check for backup files
BACKUP_COUNT=$(find "$BACKUP_PATH" -type f -name "*.dump" | wc -l)
if [[ $BACKUP_COUNT -eq 0 ]]; then
    echo "❌ No backup files found in $BACKUP_PATH"
    exit 1
fi

# Find the latest backup
LATEST_BACKUP=$(find "$BACKUP_PATH" -type f -name "*.dump" -printf "%T@ %p\n" | sort -nr | head -n1 | cut -d' ' -f2)
CHECKSUM_FILE="${LATEST_BACKUP}.sha256"

# Verify that checksum exists
if [[ ! -f "$CHECKSUM_FILE" ]]; then
    echo "❌ Checksum file not found: $CHECKSUM_FILE"
    exit 1
fi

# Verify checksum
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

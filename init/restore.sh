#!/bin/bash

BACKUP_FILE="$1"

if [[ ! -f "$BACKUP_FILE" ]]; then
    echo "❌ Backup file not found!"
    exit 1
fi

# Verify checksum
CHECKSUM_FILE="${BACKUP_FILE}.sha256"
if [[ ! -f "$CHECKSUM_FILE" ]]; then
    echo "⚠️  Checksum file not found! Cannot verify backup integrity."
else
    echo "🔍 Verifying checksum..."
    sha256sum -c "$CHECKSUM_FILE"
    if [[ $? -ne 0 ]]; then
        echo "❌ Checksum mismatch! Aborting restore."
        exit 1
    fi
    echo "✅ Checksum verified!"
fi

# Proceed with restore (example for PostgreSQL)
echo "♻️ Restoring backup..."
pg_restore -h localhost -p 5434 -U bootcamp_admin -d bootcamp_db "$BACKUP_FILE"
echo "🎉 Restore completed!"

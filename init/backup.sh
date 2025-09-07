#!/usr/bin/env bash
# Robust backup script for PostgreSQL: full logical backup (schema + data).
# Writes a gzipped plain-SQL dump by default. Can also produce compressed
# custom-format dumps with BACKUP_FORMAT=custom.
#
# Behavior:
# - Loads .env from repo root if present (useful for local runs or Actions step that didn't export env).
# - Prefers running pg_dump inside a detected Postgres container (avoids mounting /var/lib/postgresql/data on runner).
# - Falls back to running pg_dump on the host against DB_HOST:DB_PORT if docker/container is not available.
# - Produces logs under HOST_BACKUP_DIR/logs and writes last_backup_meta.txt with metadata.
#
# Environment variables (all optional except DB_USER/DB_PASSWORD/DB_NAME):
#   HOST_BACKUP_DIR  - dir to write backups (default: ./postgres_backups)
#   DB_HOST          - postgres host to connect to (default: localhost)
#   DB_PORT          - postgres port (default: 5432)
#   DB_USER          - postgres user (required)
#   DB_PASSWORD      - postgres password (required)
#   DB_NAME          - target database name (required)
#   BACKUP_FORMAT    - "plain" (default) or "custom" (custom = pg_dump -Fc)
#   BACKUP_GLOBALS   - "1" to also run pg_dumpall --globals-only and save roles/globals
#   TIMESTAMP_FMT    - timestamp format (default: %Y%m%d_%H%M%S)
#
set -euo pipefail

# Try to load .env if present (do not fail if missing)
if [ -f .env ]; then
  # shellcheck disable=SC1091
  set -o allexport
  # shellcheck source=/dev/null
  source .env || true
  set +o allexport
fi

# Defaults
HOST_BACKUP_DIR="${HOST_BACKUP_DIR:-$(pwd)/postgres_backups}"
DB_HOST="${DB_HOST:-localhost}"
DB_PORT="${DB_PORT:-5434}"
DB_USER="${DB_USER:-}"
DB_PASSWORD="${DB_PASSWORD:-}"
DB_NAME="${DB_NAME:-}"
BACKUP_FORMAT="${BACKUP_FORMAT:-plain}"
BACKUP_GLOBALS="${BACKUP_GLOBALS:-0}"
TIMESTAMP_FMT="${TIMESTAMP_FMT:-%Y%m%d_%H%M%S}"

log() { printf '%s %s\n' "$(date -u +'%Y-%m-%dT%H:%M:%SZ')" "$*"; }

# Validate required vars
if [ -z "$DB_USER" ] || [ -z "$DB_PASSWORD" ] || [ -z "$DB_NAME" ]; then
  log "ERROR: DB_USER, DB_PASSWORD and DB_NAME must be set in environment (or .env)"
  exit 2
fi

mkdir -p "$HOST_BACKUP_DIR"
mkdir -p "$HOST_BACKUP_DIR/logs"

TIMESTAMP=$(date -u +"$TIMESTAMP_FMT")
if [ "$BACKUP_FORMAT" = "custom" ]; then
  SUFFIX="dump"
  OUTFILE="$HOST_BACKUP_DIR/${DB_NAME}_${TIMESTAMP}.dump.gz"
else
  SUFFIX="sql"
  OUTFILE="$HOST_BACKUP_DIR/${DB_NAME}_${TIMESTAMP}.sql.gz"
fi
DUMPLOG="$HOST_BACKUP_DIR/logs/pg_dump_${TIMESTAMP}.log"
DIAGLOG="$HOST_BACKUP_DIR/logs/diag_${TIMESTAMP}.log"

log "Starting backup for database '$DB_NAME' -> $OUTFILE"
log "Settings: HOST_BACKUP_DIR=$HOST_BACKUP_DIR DB_HOST=$DB_HOST DB_PORT=$DB_PORT DB_USER=$DB_USER BACKUP_FORMAT=$BACKUP_FORMAT BACKUP_GLOBALS=$BACKUP_GLOBALS"

# Find a running Postgres container matching common images (prefer exact tag if possible)
find_pg_container() {
  # Try the exact image tag first (if available in container list)
  docker ps --filter "ancestor=postgres:17-alpine" --format "{{.ID}}" 2>/dev/null | head -n1 || \
  docker ps --filter "ancestor=postgres:17" --format "{{.ID}}" 2>/dev/null | head -n1 || \
  docker ps --filter "ancestor=postgres" --format "{{.ID}}" 2>/dev/null | head -n1 || true
}

write_diagnostics() {
  local cid="$1"
  log "Writing diagnostics to $DIAGLOG"
  {
    echo "=== date ==="
    date -u
    echo
    echo "=== docker ps (short) ==="
    docker ps --no-trunc --format 'table {{.ID}}\t{{.Image}}\t{{.Names}}\t{{.Status}}'
    echo
    echo "=== psql - list databases ==="
    docker exec -e PGPASSWORD="$DB_PASSWORD" "$cid" psql -U "$DB_USER" -d postgres -c "\l+" 2>&1 || true
    echo
    echo "=== table counts in target DB (by schema) ==="
    docker exec -e PGPASSWORD="$DB_PASSWORD" "$cid" psql -U "$DB_USER" -d "$DB_NAME" -t -c \
      "SELECT table_schema, count(*) FROM information_schema.tables WHERE table_catalog = current_database() AND table_schema NOT IN ('pg_catalog','information_schema') GROUP BY table_schema ORDER BY table_schema;" 2>&1 || true
    echo
  } > "$DIAGLOG" 2>&1 || true
  log "Diagnostics written to $DIAGLOG"
}

# Detect Docker and container
CONTAINER_ID=""
if command -v docker >/dev/null 2>&1; then
  CONTAINER_ID=$(find_pg_container || true)
fi

# Perform backup
if [ -n "$CONTAINER_ID" ] && { [ "$DB_HOST" = "localhost" ] || [ "$DB_HOST" = "127.0.0.1" ] || [ -z "$DB_HOST" ]; }; then
  log "Detected Postgres container ($CONTAINER_ID). Running pg_dump inside container."
  write_diagnostics "$CONTAINER_ID"

  if [ "$BACKUP_FORMAT" = "custom" ]; then
    # Create an intermediate file inside runner (avoid streaming issues with -F c)
    TMP_OUT="$HOST_BACKUP_DIR/${DB_NAME}_${TIMESTAMP}.dump"
    docker exec -e PGPASSWORD="$DB_PASSWORD" "$CONTAINER_ID" pg_dump -U "$DB_USER" -d "$DB_NAME" -F c > "$TMP_OUT" 2> "$DUMPLOG" || {
      log "pg_dump (container, custom) failed; see $DUMPLOG"
      exit 3
    }
    gzip -c9 "$TMP_OUT" > "$OUTFILE"
    rm -f "$TMP_OUT"
  else
    # plain SQL: run pg_dump inside container and capture stdout, preserving exit code
    TMP_SQL="$HOST_BACKUP_DIR/temp_dump_${TIMESTAMP}.sql"
    # Run pg_dump inside the container; capture stdout to temp file and stderr to log
    docker exec -e PGPASSWORD="$DB_PASSWORD" "$CONTAINER_ID" bash -lc "pg_dump -U '$DB_USER' -d '$DB_NAME'" > "$TMP_SQL" 2> "$DUMPLOG" || true
    if [ -s "$TMP_SQL" ]; then
      gzip -c9 "$TMP_SQL" > "$OUTFILE"
      rm -f "$TMP_SQL"
    else
      log "pg_dump (container, plain) produced no output; check $DUMPLOG"
      rm -f "$TMP_SQL" || true
      # keep logs and metadata for inspection
      echo "ERROR: pg_dump produced no output" >> "$DUMPLOG"
      # Do not silently succeed; exit with non-zero so CI can surface the issue
      exit 3
    fi
  fi
else
  log "No appropriate Postgres container detected or DB_HOST is remote; connecting to $DB_HOST:$DB_PORT"
  export PGPASSWORD="$DB_PASSWORD"
  if [ "$BACKUP_FORMAT" = "custom" ]; then
    TMP_OUT="$HOST_BACKUP_DIR/${DB_NAME}_${TIMESTAMP}.dump"
    if pg_dump -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" -F c > "$TMP_OUT" 2> "$DUMPLOG"; then
      gzip -c9 "$TMP_OUT" > "$OUTFILE"
      rm -f "$TMP_OUT"
    else
      log "pg_dump (remote/custom) failed; see $DUMPLOG"
      exit 4
    fi
  else
    TMP_SQL="$HOST_BACKUP_DIR/temp_dump_${TIMESTAMP}.sql"
    if pg_dump -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" > "$TMP_SQL" 2> "$DUMPLOG"; then
      gzip -c9 "$TMP_SQL" > "$OUTFILE"
      rm -f "$TMP_SQL"
    else
      log "pg_dump (remote/plain) failed; see $DUMPLOG"
      rm -f "$TMP_SQL" || true
      exit 4
    fi
  fi
fi

# Optionally dump globals (roles)
if [ "${BACKUP_GLOBALS:-0}" = "1" ]; then
  log "Backing up globals (roles) with pg_dumpall --globals-only"
  GLOBALS_OUT="$HOST_BACKUP_DIR/globals_${TIMESTAMP}.sql.gz"
  GLOBALS_LOG="$HOST_BACKUP_DIR/logs/pg_dumpall_${TIMESTAMP}.log"
  if [ -n "$CONTAINER_ID" ] && { [ "$DB_HOST" = "localhost" ] || [ "$DB_HOST" = "127.0.0.1" ] || [ -z "$DB_HOST" ]; }; then
    docker exec -e PGPASSWORD="$DB_PASSWORD" "$CONTAINER_ID" pg_dumpall --globals-only > "$HOST_BACKUP_DIR/globals_${TIMESTAMP}.sql" 2> "$GLOBALS_LOG" || true
    gzip -c9 "$HOST_BACKUP_DIR/globals_${TIMESTAMP}.sql" > "$GLOBALS_OUT" && rm -f "$HOST_BACKUP_DIR/globals_${TIMESTAMP}.sql"
  else
    pg_dumpall --globals-only > "$HOST_BACKUP_DIR/globals_${TIMESTAMP}.sql" 2> "$GLOBALS_LOG" || true
    gzip -c9 "$HOST_BACKUP_DIR/globals_${TIMESTAMP}.sql" > "$GLOBALS_OUT" && rm -f "$HOST_BACKUP_DIR/globals_${TIMESTAMP}.sql"
  fi
  log "Globals saved to $GLOBALS_OUT (logs: $GLOBALS_LOG)"
fi

# Final checks and metadata
if [ -f "$OUTFILE" ]; then
  filesize=$(stat -c%s "$OUTFILE" || echo 0)
  log "Backup completed successfully: $OUTFILE (${filesize} bytes)"
  cat > "$HOST_BACKUP_DIR/last_backup_meta.txt" <<EOF
filename=$(basename "$OUTFILE")
path=$OUTFILE
timestamp=$(date -u +%Y-%m-%dT%H:%M:%SZ)
size_bytes=$filesize
db_name=$DB_NAME
db_host=$DB_HOST
db_port=$DB_PORT
db_user=$DB_USER
EOF
  log "Metadata written to $HOST_BACKUP_DIR/last_backup_meta.txt"
  exit 0
else
  log "ERROR: expected backup file not created: $OUTFILE"
  exit 5
fi
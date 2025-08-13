# Use the official PostgreSQL Alpine image
FROM postgres:17-alpine

# Copy the initialization script from your local 'init' subfolder.
# This script creates the database, users, tables, etc.
COPY init/init.sql /docker-entrypoint-initdb.d/init.sql

# Copy the backup script from your local 'init' subfolder.
COPY init/backup.sh /usr/local/bin/backup.sh

# Make the backup script executable and ensure the postgres user owns it.
# The default user context here is sufficient.
RUN chmod +x /usr/local/bin/backup.sh && \
    chown postgres:postgres /usr/local/bin/backup.sh
FROM postgres:17-alpine

USER root
RUN mkdir -p /ts_bootcamp_data \
    && chown -R postgres:postgres /ts_bootcamp_data \
    && chmod 700 /ts_bootcamp_data

USER postgres
COPY init/init.sql /docker-entrypoint-initdb.d/init.sql

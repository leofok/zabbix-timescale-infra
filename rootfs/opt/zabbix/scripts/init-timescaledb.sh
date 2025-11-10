#!/usr/bin/env bash
set -euo pipefail

COMPOSE_FILE="${1:-docker-compose_v3_ubuntu_pgsql_latest.yaml}"

# 顯示 shared_preload_libraries
docker compose -f "$COMPOSE_FILE" exec -T postgres-server \
  sh -lc 'psql -U "$(cat /run/secrets/POSTGRES_USER)" -d "$POSTGRES_DB" \
          -c "SHOW shared_preload_libraries;"'

# 建立 TimescaleDB extension
docker compose -f "$COMPOSE_FILE" exec -T postgres-server \
  sh -lc '
    PGPASSWORD="$(cat /run/secrets/POSTGRES_PASSWORD)" \
    psql -v ON_ERROR_STOP=1 \
      -U "$(cat /run/secrets/POSTGRES_USER)" -d "$POSTGRES_DB" \
      -c "CREATE EXTENSION IF NOT EXISTS timescaledb CASCADE;"
  '

# 匯入 Zabbix 官方 timescaledb schema
docker compose -f "$COMPOSE_FILE" exec zabbix-server \
  bash -lc 'cat /usr/share/doc/zabbix-server-postgresql/timescaledb.sql' \
| docker compose -f "$COMPOSE_FILE" exec -T postgres-server \
    sh -lc '
      PGPASSWORD="$(cat /run/secrets/POSTGRES_PASSWORD)" \
      psql -v ON_ERROR_STOP=1 \
        -U "$(cat /run/secrets/POSTGRES_USER)" -d "$POSTGRES_DB"
    '

# 驗證 hypertables
docker compose -f "$COMPOSE_FILE" exec -T postgres-server \
  sh -lc '
    PGPASSWORD="$(cat /run/secrets/POSTGRES_PASSWORD)" \
    psql -U "$(cat /run/secrets/POSTGRES_USER)" -d "$POSTGRES_DB" \
      -c "SELECT hypertable_name FROM timescaledb_information.hypertables ORDER BY 1;"
  '

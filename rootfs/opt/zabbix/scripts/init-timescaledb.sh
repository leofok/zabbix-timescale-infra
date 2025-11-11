#!/usr/bin/env bash
set -euo pipefail

COMPOSE_FILE="${1:-docker-compose_v3_ubuntu_pgsql_latest.yaml}"
COMPOSE_DIR="${2:-.}"   # 預設當前目錄
OVERRIDE="/opt/zabbix/override-timescale.yml"

# 組合 compose 參數：存在 override 時一併帶上
COMPOSE_ARGS=(-f "$COMPOSE_FILE")
[[ -f "$OVERRIDE" ]] && COMPOSE_ARGS+=(-f "$OVERRIDE")

cd "$COMPOSE_DIR"

# 顯示 shared_preload_libraries
docker compose "${COMPOSE_ARGS[@]}" exec -T postgres-server \
  sh -lc 'psql -U "$(cat /run/secrets/POSTGRES_USER)" -d "$POSTGRES_DB" \
          -c "SHOW shared_preload_libraries;"'

# 建立 TimescaleDB extension（若已存在不報錯）
docker compose "${COMPOSE_ARGS[@]}" exec -T postgres-server \
  sh -lc '
    PGPASSWORD="$(cat /run/secrets/POSTGRES_PASSWORD)" \
    psql -v ON_ERROR_STOP=1 \
      -U "$(cat /run/secrets/POSTGRES_USER)" -d "$POSTGRES_DB" \
      -c "CREATE EXTENSION IF NOT EXISTS timescaledb CASCADE;"
  '

# 匯入 Zabbix 官方 timescaledb schema（可重覆執行）
docker compose "${COMPOSE_ARGS[@]}" exec zabbix-server \
  bash -lc 'cat /usr/share/doc/zabbix-server-postgresql/timescaledb.sql' \
| docker compose "${COMPOSE_ARGS[@]}" exec -T postgres-server \
    sh -lc '
      PGPASSWORD="$(cat /run/secrets/POSTGRES_PASSWORD)" \
      psql -v ON_ERROR_STOP=1 \
        -U "$(cat /run/secrets/POSTGRES_USER)" -d "$POSTGRES_DB"
    '

# 驗證 hypertables
docker compose "${COMPOSE_ARGS[@]}" exec -T postgres-server \
  sh -lc '
    PGPASSWORD="$(cat /run/secrets/POSTGRES_PASSWORD)" \
    psql -U "$(cat /run/secrets/POSTGRES_USER)" -d "$POSTGRES_DB" \
      -c "SELECT hypertable_name FROM timescaledb_information.hypertables ORDER BY 1;"
  '

# 🔁 關鍵：重啟 zabbix-server 讓設定完整生效
docker compose "${COMPOSE_ARGS[@]}" restart zabbix-server

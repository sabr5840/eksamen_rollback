#!/usr/bin/env bash
set -euo pipefail

URL="${1:-http://localhost:8081/health}"
MAX_WAIT_SECONDS="${MAX_WAIT_SECONDS:-30}"

echo "Healthcheck: $URL (max ${MAX_WAIT_SECONDS}s)"

start_ts=$(date +%s)
while true; do
  if curl -fsS "$URL" >/dev/null 2>&1; then
    echo "✅ Healthy"
    exit 0
  fi

  now_ts=$(date +%s)
  elapsed=$((now_ts - start_ts))
  if [ "$elapsed" -ge "$MAX_WAIT_SECONDS" ]; then
    echo "❌ Unhealthy after ${elapsed}s"
    exit 1
  fi

  sleep 2
done

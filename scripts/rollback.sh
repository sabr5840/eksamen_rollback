#!/usr/bin/env bash
set -euo pipefail

ROLLBACK_TAG="${1:-}"
if [ -z "$ROLLBACK_TAG" ]; then
  echo "Usage: ./scripts/rollback.sh <IMAGE_TAG>"
  exit 1
fi

unset FAIL_HEALTH
unset DEPLOY_FAIL_HEALTH

echo "Rolling back to IMAGE_TAG=$ROLLBACK_TAG"

cat > .env <<EOF2
IMAGE_TAG=$ROLLBACK_TAG
FAIL_HEALTH=0
EOF2

docker compose build
docker compose up -d

./scripts/healthcheck.sh

echo "✅ Rollback complete."

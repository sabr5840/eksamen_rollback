#!/usr/bin/env bash
set -euo pipefail

NEW_TAG="${1:-}"
if [ -z "$NEW_TAG" ]; then
  echo "Usage: ./scripts/deploy.sh <IMAGE_TAG>"
  exit 1
fi

STATE_DIR=".deploy"
mkdir -p "$STATE_DIR"

LAST_GOOD_FILE="$STATE_DIR/last_good_tag"
CURRENT_FILE="$STATE_DIR/current_tag"

LAST_GOOD_TAG=""
if [ -f "$LAST_GOOD_FILE" ]; then
  LAST_GOOD_TAG="$(cat "$LAST_GOOD_FILE")"
fi

# Only for simulating broken deploys
DEPLOY_FAIL_HEALTH="${DEPLOY_FAIL_HEALTH:-0}"

echo "Deploying IMAGE_TAG=$NEW_TAG"
echo "$NEW_TAG" > "$CURRENT_FILE"

cat > .env <<EOF2
IMAGE_TAG=$NEW_TAG
FAIL_HEALTH=$DEPLOY_FAIL_HEALTH
EOF2

docker compose build
docker compose up -d

if ./scripts/healthcheck.sh; then
  echo "✅ Deploy OK. Marking $NEW_TAG as last known good."
  echo "$NEW_TAG" > "$LAST_GOOD_FILE"
  exit 0
fi

echo "❌ Deploy failed. Rolling back..."
if [ -n "$LAST_GOOD_TAG" ]; then
  ./scripts/rollback.sh "$LAST_GOOD_TAG"
else
  echo "No last known good version"
  exit 1
fi

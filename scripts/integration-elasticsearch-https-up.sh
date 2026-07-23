#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$ROOT/scripts/integration-elasticsearch-https-prepare.sh"

docker compose \
  -f "$ROOT/docker-compose.integration.yml" \
  -p "$DBTOOL_IT_PROJECT" \
  --profile elasticsearch-https \
  up -d --wait --wait-timeout "${DBTOOL_IT_WAIT_TIMEOUT:-300}" \
  elasticsearch-https

docker compose \
  -f "$ROOT/docker-compose.integration.yml" \
  -p "$DBTOOL_IT_PROJECT" \
  --profile elasticsearch-https \
  ps elasticsearch-https

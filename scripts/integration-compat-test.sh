#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$ROOT/scripts/integration-env.sh"

"$ROOT/scripts/integration-compat-up.sh"

if [[ "${DBTOOL_IT_KEEP_SERVICES:-0}" != "1" ]]; then
  trap '"$ROOT/scripts/integration-down.sh"' EXIT
fi

export DBTOOL_RUN_COMPAT_INTEGRATION=1
export DBTOOL_RUN_MARIADB_COMPAT=1
export DBTOOL_RUN_VALKEY_COMPAT=1

run_exact_kv_mutation() {
  local dsn="$1"

  DBTOOL_IT_REDIS_DSN="$dsn" cargo test -p adapter-redis \
    tests::redis_live_budgeted_kv_mutations_reject_before_write_and_round_trip \
    -- --exact --nocapture
}

if [[ "${DBTOOL_IT_COMPAT_EXTRA:-0}" == "1" ]]; then
  export DBTOOL_RUN_KEYDB_COMPAT=1
  export DBTOOL_RUN_DRAGONFLY_COMPAT=1
fi

cargo test -p dbtool-cli --test live_services compat_live -- --nocapture
cargo test -p dbtool-cli --test kv_binary_raw \
  redis_compatible_products_enforce_strict_scan_and_raw_contracts -- --exact --nocapture
run_exact_kv_mutation "$DBTOOL_IT_VALKEY_DSN"
if [[ "${DBTOOL_IT_COMPAT_EXTRA:-0}" == "1" ]]; then
  run_exact_kv_mutation "$DBTOOL_IT_KEYDB_DSN"
  run_exact_kv_mutation "$DBTOOL_IT_DRAGONFLY_DSN"
fi
cargo test -p dbtool-cli --test live_sql_params -- --nocapture
cargo test -p dbtool-cli --test named_sql_atomic mariadb_named_product -- --nocapture

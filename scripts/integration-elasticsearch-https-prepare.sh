#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$ROOT/scripts/integration-env.sh"

case "$DBTOOL_IT_ELASTICSEARCH_HTTPS_DIR" in
  /*) ;;
  *) DBTOOL_IT_ELASTICSEARCH_HTTPS_DIR="$ROOT/$DBTOOL_IT_ELASTICSEARCH_HTTPS_DIR" ;;
esac
export DBTOOL_IT_ELASTICSEARCH_HTTPS_DIR

CERT_DIR="$DBTOOL_IT_ELASTICSEARCH_HTTPS_DIR/certs"
PRIVATE_DIR="$DBTOOL_IT_ELASTICSEARCH_HTTPS_DIR/private"
mkdir -p "$CERT_DIR" "$PRIVATE_DIR"

CERT_RENEWAL_SECONDS="${DBTOOL_IT_ELASTICSEARCH_HTTPS_CERT_RENEWAL_SECONDS:-3600}"

cert_is_current() {
  local cert="$1"
  [[ -f "$cert" ]] && openssl x509 \
    -checkend "$CERT_RENEWAL_SECONDS" \
    -noout \
    -in "$cert" >/dev/null 2>&1
}

if [[ "${DBTOOL_IT_ELASTICSEARCH_HTTPS_REGENERATE_CERTS:-0}" == "1" ]] \
  || [[ ! -f "$PRIVATE_DIR/ca-key.pem" ]] \
  || [[ ! -f "$CERT_DIR/node-key.pem" ]] \
  || ! cert_is_current "$CERT_DIR/ca.pem" \
  || ! cert_is_current "$CERT_DIR/node.pem"; then
  rm -f "$CERT_DIR"/*
  rm -f "$PRIVATE_DIR"/*
fi

if [[ ! -f "$CERT_DIR/ca.pem" ]]; then
  openssl req \
    -x509 \
    -newkey rsa:2048 \
    -nodes \
    -days "${DBTOOL_IT_ELASTICSEARCH_HTTPS_CERT_DAYS:-7}" \
    -subj "/CN=dbtool-it-elasticsearch-https-ca" \
    -keyout "$PRIVATE_DIR/ca-key.pem" \
    -out "$CERT_DIR/ca.pem" >/dev/null 2>&1
fi

if [[ ! -f "$CERT_DIR/node.pem" ]]; then
  cat >"$CERT_DIR/node-openssl.cnf" <<'EOF'
[req]
distinguished_name = req_distinguished_name
req_extensions = v3_req
prompt = no

[req_distinguished_name]
CN = dbtool-it-elasticsearch-https

[v3_req]
basicConstraints = CA:FALSE
keyUsage = digitalSignature, keyEncipherment
extendedKeyUsage = serverAuth
subjectAltName = @alt_names

[alt_names]
DNS.1 = localhost
DNS.2 = elasticsearch-https
IP.1 = 127.0.0.1
EOF

  openssl req \
    -newkey rsa:2048 \
    -nodes \
    -keyout "$CERT_DIR/node-key.pem" \
    -out "$CERT_DIR/node.csr" \
    -config "$CERT_DIR/node-openssl.cnf" >/dev/null 2>&1
  openssl x509 \
    -req \
    -in "$CERT_DIR/node.csr" \
    -CA "$CERT_DIR/ca.pem" \
    -CAkey "$PRIVATE_DIR/ca-key.pem" \
    -CAcreateserial \
    -days "${DBTOOL_IT_ELASTICSEARCH_HTTPS_CERT_DAYS:-7}" \
    -extensions v3_req \
    -extfile "$CERT_DIR/node-openssl.cnf" \
    -out "$CERT_DIR/node.pem" >/dev/null 2>&1
fi

chmod 0644 "$CERT_DIR"/*.pem
chmod 0600 "$PRIVATE_DIR/ca-key.pem"

export DBTOOL_IT_ELASTICSEARCH_HTTPS_CA="$CERT_DIR/ca.pem"
export DBTOOL_IT_ELASTICSEARCH_HTTPS_DSN="${DBTOOL_IT_ELASTICSEARCH_HTTPS_DSN:-elasticsearch+https://elastic:${DBTOOL_IT_ELASTICSEARCH_HTTPS_PASSWORD}@127.0.0.1:${DBTOOL_IT_ELASTICSEARCH_HTTPS_PORT}?tls-ca=$DBTOOL_IT_ELASTICSEARCH_HTTPS_CA}"

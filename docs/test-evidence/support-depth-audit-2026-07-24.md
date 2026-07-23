# 2026-07-24 Support-Depth Audit Evidence

Result: local supported-product campaign PASS with explicit architecture,
host-runtime, resource, and external-endpoint boundaries.

Environment:

- macOS arm64
- Docker Engine 29.4.0, overlay2, 2 CPUs, 8,395,403,264 bytes memory
- Rust/Cargo 1.96.0
- disposable resources use the `dbtool_it_` prefix

## Live Product Matrix

| Family | Products and versions | Current campaign result | Depth exercised |
| --- | --- | --- | --- |
| SQL | PostgreSQL 16.14, MySQL 8.4.9 | PASS | CRUD, catalogs, typed values, bounds, guarded writes, server timeout, bound parameters, atomic import/rollback, cleanup |
| SQL-compatible | MariaDB 11.4.12, CockroachDB 24.3.8, TimescaleDB 2.17.2/PG16, TiDB 8.5.6 | PASS | named-product CRUD/catalog/type/bounds, direct bound parameters, atomic import/late-failure rollback, cleanup |
| CQL | Cassandra 5.0.8, ScyllaDB 2026.1.8 | PASS | CQL and SQL-compatible CRUD, schema/PK metadata, typed collections, paging/budgets, guarded cleanup, file fixture |
| KV/document | Redis 7.4.9, Valkey 8.1.8, KeyDB 6.3 image, Dragonfly 1.39.0, MongoDB 7.0.37 | PASS | binary/empty/missing/TTL, strict SCAN, exact raw/mutation budgets, one/many document mutations and cleanup |
| Search/time series | OpenSearch 2.17.1 HTTP and security HTTPS, Elasticsearch 8.15.5 HTTP and HTTPS, Prometheus 2.55.1 | PASS | exact search CRUD/catalog/budgets/cleanup; CA/auth negative tests; remote write/range/catalog and cleanup |
| Messaging | Redis Streams/PubSub, Redpanda 24.3.6 Kafka API, RabbitMQ 3.13.7 AMQP/management, NATS 2.10.29 | PASS | bounded produce/consume, ACK/group/admin/detail/lag where supported, exact budgets, cleanup |
| Messaging TLS | RabbitMQ 3.13.7 AMQPS, NATS 2.10.29 TLS | PASS | CA-backed connection, produce/consume/admin lifecycle |

Commands:

```text
./scripts/verify.sh
./scripts/integration-db-suite.sh
DBTOOL_IT_DB_SUITE_PHASES='compat-extra cassandra scylla cassandra-fixture messaging messaging-native messaging-tls observability opensearch-security elasticsearch' DBTOOL_IT_DB_SUITE_CONTINUE=1 ./scripts/integration-db-suite.sh
DBTOOL_IT_DB_SUITE_PHASES='cassandra-fixture messaging elasticsearch-https' DBTOOL_IT_DB_SUITE_CONTINUE=1 ./scripts/integration-db-suite.sh
DBTOOL_IT_DB_SUITE_DRY_RUN=1 DBTOOL_IT_DB_SUITE_PHASES=local-heavy ./scripts/integration-db-suite.sh
```

The first default run found four stale test contracts rather than connector
failures: mutation lock timeouts were incorrectly classified as retryable,
Redis typed arrays were asserted as legacy raw arrays, fixture-image resource
names were stale, and MariaDB JSON was assumed to have a native wire type. The
rerun passed after aligning the tests with the public v2 envelope,
`OUTCOME_INDETERMINATE` mutation contract, current fixture names, and MariaDB's
lossless LONGTEXT/binary JSON alias.

The first heavy run additionally found a Cassandra collection fixture using
the old raw-array shape and a RabbitMQ management race after AMQP queue
declaration. The focused rerun passed after asserting the typed collection
envelope and retrying only RabbitMQ's documented transient 404/statistics
population states.

Elasticsearch HTTPS is product-native evidence, not the synthetic TLS search
harness: Elasticsearch 8.15.5 ran with X-Pack security, Basic Auth, a generated
CA/server certificate, hostname-valid SANs, and the registered
`elasticsearch+https://` scheme. Wrong credentials were rejected with HTTP
401, omission of the CA was rejected during certificate validation, and the
full index/document lifecycle ended with no test index.

## Honest Non-Pass Boundaries

| Product/surface | Status | Current evidence |
| --- | --- | --- |
| SQL Server | architecture-gated on this host | `integration-sqlserver-up.sh` returned 78 on arm64; the product image is x86_64-only. Existing x86_64 evidence remains the product proof. |
| IBM Db2 | BLOCKED | a supported host-installed IBM 64-bit client is unavailable; service-free adapter/budget tests pass, but no live SQL claim is made. |
| Redshift | EXTERNAL | `DBTOOL_IT_REDSHIFT_DSN` was not supplied. |
| AutoMQ, WarpStream, Confluent | EXTERNAL | no vendor DSN was supplied; the runner now requires key/header/partition/timestamp/cursor fidelity when endpoints are provided. |
| TiDB secure HA drills | not rerun locally | the 2 CPU allocation is below the documented secure-HA profile requirement; single-cluster TiDB passed. |
| RabbitMQ management HTTPS | NOT_IMPLEMENTED | the admin adapter is deliberately registered only for `rabbitmq+http://`; direct AMQPS is tested, but management HTTPS requires a TLS HTTP transport. |

Cleanup: PASS. The final `docker ps --filter name=dbtool-it` output was empty
after the HTTPS profile was added to the common teardown path.

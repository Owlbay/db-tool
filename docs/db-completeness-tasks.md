# Database Capability Completeness Tasks

This is the execution ledger for real dbtool backend verification. It is
separate from `docs/tasks.md`: implementation, a runnable harness, and a real
successful service run are intentionally different states.

## Scope And Safety

- Only disposable resources prefixed with `dbtool_it_` are created or mutated.
- "All contents" means every row/document/key/message created by the fixture
  named in an evidence file. The suite never performs an unbounded dump of an
  arbitrary user or production database.
- Credentials, raw DSNs, certificates, and full container logs are not committed.
- A skipped external endpoint or a missing runtime is not a pass.
- Heavy profiles run serially on the current 2 CPU / 8 GiB Docker allocation.

## Status Model

`NOT_RUN -> HARNESS_READY -> LIVE_PASS -> COMPLETE`

- `HARNESS_READY`: code and an invocation path exist, but the real product has
  not passed in the current validation campaign.
- `LIVE_PASS`: the real product completed its capability-family checklist and
  has a committed evidence file.
- `COMPLETE`: `LIVE_PASS` plus documentation and the manifest are synchronized.
- `BLOCKED`: a concrete architecture/runtime prerequisite is unavailable.
- `EXTERNAL`: a real endpoint and credentials must be supplied.
- `PARTIAL`: alias routing or a compatible harness passed, not the named product.

## Capability-Family Checklists

| Family | Required operations for a complete result |
| --- | --- |
| SQL | ping/caps, schemas/tables, CREATE, INSERT, SELECT, UPDATE, targeted DELETE, schema/index metadata, typed values, limit/truncation, bound-parameter import with whole-batch rollback where advertised, write guard/confirm, cleanup |
| CQL | ping/caps, keyspaces/tables, CREATE, INSERT, SELECT, UPDATE, targeted DELETE, schema/primary-key metadata, typed values, limit, write guard, cleanup |
| KV/cache | ping/caps, text/binary/empty SET+GET, missing distinction, overwrite, TTL, exact N/N+1 SCAN, multi-page/error propagation, bounded typed raw read, confirmed allowlisted raw mutation, forbidden/unknown rejection, DELETE, post-delete read, cleanup |
| Document | ping/caps with explicit one/many operations, collections, INSERT, FIND, single UPDATE/DELETE, confirmed multi UPDATE/DELETE with exact counts, read aggregate, exact confirmed `$out/$merge`, empty result verification, cleanup |
| Search | ping/caps, write guard, exact auto-ID/stable-ID writes, list indices, search/get readback, patch update, document delete, target-bound index delete, and zero-index cleanup |
| Time series | ping/caps, write guard, remote write, measurement list, range readback; update/delete are not applicable to the Prometheus model |
| Messaging | ping/caps, write guard, produce/publish, bounded consume, list/detail/lag where the protocol supports them, timeout/ack behavior, cleanup where the public API supports it |

## Execution Task Table

The machine-readable source for this table is
`testdata/db-completeness.manifest`. `Commit` identifies the campaign commit
that synchronized the completed evidence for that task; earlier implementation
and test-hardening commits remain listed inside each evidence file.

| Task | Family | Product / scheme | Environment | Harness | Live result | Evidence | Commit / boundary |
| --- | --- | --- | --- | --- | --- | --- | --- |
| DB-SQLITE-001 | SQL | SQLite `sqlite:` | service-free | Ready | COMPLETE | `docs/test-evidence/sqlite.md` | `a6e60c5`, IF-T78 exact mutation refresh |
| DB-POSTGRES-001 | SQL | PostgreSQL `postgres://` | Docker base | Ready | COMPLETE | `docs/test-evidence/postgresql.md` | `a6e60c5`, IF-T78 exact mutation refresh |
| DB-MYSQL-001 | SQL | MySQL `mysql://` | Docker base | Ready | COMPLETE | `docs/test-evidence/mysql.md` | `a6e60c5`, IF-T78 exact mutation refresh |
| DB-MARIADB-001 | SQL | MariaDB `mariadb://` | Docker compat | Ready | COMPLETE | `docs/test-evidence/mariadb.md` | `6f423fb`, `152dc18`; CRUD/types plus named-product atomic import and late-failure rollback |
| DB-TIDB-001 | SQL | TiDB `tidb://` | Docker tidb | Ready | COMPLETE | `docs/test-evidence/tidb.md` | `4c2faa8`, `152dc18`; basic/secure/proxy/resilience plus named-product atomic import rollback passed |
| DB-COCKROACH-001 | SQL | CockroachDB `cockroach://` | Docker pg-compat | Ready | COMPLETE | `docs/test-evidence/cockroachdb.md` | `a776d20`, `152dc18`; single-node SQL surface plus named-product atomic import rollback |
| DB-TIMESCALE-001 | SQL | TimescaleDB `timescale://` | Docker pg-compat | Ready | COMPLETE | `docs/test-evidence/timescaledb.md` | `c2a77fe`, `152dc18`; generic SQL surface plus named-product atomic import rollback |
| DB-SQLSERVER-001 | SQL | SQL Server `sqlserver://` | GitHub x86_64 Docker | Ready | COMPLETE | `docs/test-evidence/sqlserver.md` | `1fd88e6`; pinned SQL Server 2022 CU26 completed adapter budgets plus product CRUD/types/catalog/guard/cleanup |
| DB-REDSHIFT-001 | SQL | Redshift `redshift://` | external | Ready | EXTERNAL | - | `DBTOOL_IT_REDSHIFT_DSN` is not supplied |
| DB-CASSANDRA-001 | CQL | Cassandra `cassandra://` | Docker cassandra | Ready | COMPLETE | `docs/test-evidence/cassandra.md` | `6fcd23c`, `94f3ffb`, IF-T78 exact CQL + SQL-compatible write/keyspace cleanup refresh |
| DB-SCYLLA-001 | CQL | ScyllaDB `scylla://` | Docker scylla | Ready | COMPLETE | `docs/test-evidence/scylladb.md` | `336f4bd`, `1fd88e6`; real ScyllaDB 2026.1.8 arm64 and GitHub x86_64 CRUD/types/bounds/input-budget/cleanup |
| DB-DB2-001 | SQL/Db2 | IBM Db2 `db2://` | self-hosted x86_64 + installed IBM client + Docker server | Ready | BLOCKED | `docs/test-evidence/db2-host-runtime-blocker.md` | service-free exact/budget tests PASS; generic hosted runners reached a healthy pinned product and registered x86-64 `libdb2o`, but copied server libraries failed `SQLAllocHandle(HENV)`; a supported `db2-client` runner is not provisioned |
| DB-REDIS-001 | KV/cache | Redis `redis://` | Docker base | Ready | COMPLETE | `docs/test-evidence/redis.md` | `cfbb998`, IF-T78 exact SET/restore/DEL/raw mutation refresh |
| DB-VALKEY-001 | KV/cache | Valkey `valkey://` | Docker compat | Ready | COMPLETE | `docs/test-evidence/valkey.md` | `1ceffc8`, `29b3126`, `1e82951`; atomic TTL/artifact plus strict SCAN/RAW/non-UTF8/recursive-response proof |
| DB-KEYDB-001 | KV/cache | KeyDB `keydb://` | Docker compat-extra | Ready | COMPLETE | `docs/test-evidence/keydb.md` | `1ceffc8`, `29b3126`, `1e82951`; atomic TTL/artifact plus strict SCAN/RAW/non-UTF8/recursive-response proof |
| DB-DRAGONFLY-001 | KV/cache | Dragonfly `dragonfly://` | Docker compat-extra | Ready | COMPLETE | `docs/test-evidence/dragonfly.md` | `1ceffc8`, `29b3126`, `1e82951`; integer TIME/artifact plus strict SCAN/RAW/non-UTF8/recursive-response proof |
| DB-MONGO-001 | Document | MongoDB `mongodb://` | Docker base | Ready | COMPLETE | `docs/test-evidence/mongodb.md` | `83db841`, `ab06b88`, IF-T78 seven exact mutations including `$out/$merge` and zero collection residual |
| DB-OPENSEARCH-001 | Search | OpenSearch `opensearch://` | Docker observability | Ready | COMPLETE | `docs/test-evidence/opensearch.md` | `3822948`, `4b6b6e2`, IF-T78 five exact mutations, every fixture document read back, zero test indices |
| DB-OPENSEARCH-TLS-001 | Search | OpenSearch security HTTPS | Docker opensearch-security | Ready | COMPLETE | `docs/test-evidence/opensearch-security.md` | `b9dd9fd`, `e0ce46f`; real plugin CA/auth failures, full CRUD, exact reads, target-bound deletion and public cleanup PASS |
| DB-ELASTICSEARCH-001 | Search | Elasticsearch `elasticsearch://`, `elasticsearch+https://` | Docker elasticsearch / elasticsearch-https | Ready | COMPLETE | `docs/test-evidence/elasticsearch.md` | `3822948`, `4b6b6e2`, IF-T78 exact mutations plus 2026-07-24 X-Pack HTTPS/auth/CA refresh |
| DB-PROMETHEUS-001 | Time series | Prometheus `prometheus://` | Docker observability | Ready | COMPLETE | `docs/test-evidence/prometheus.md` | `3c9c2d4`, IF-T78 exact remote-write and zero-series cleanup refresh |
| DB-VICTORIAMETRICS-001 | Time series | VictoriaMetrics `victoriametrics://` | Docker victoriametrics | Ready | COMPLETE | `docs/test-evidence/victoriametrics.md` | `dac0b23`, `4e200e1`; real v1.148.0 Prometheus-compatible write/catalog/range/budget lifecycle |
| DB-REDIS-MQ-001 | Messaging | Redis Streams/PubSub | Docker messaging | Ready | COMPLETE | `docs/test-evidence/redis-messaging.md` | `d2c88a2`, IF-T48; Redis/Valkey/KeyDB/Dragonfly group replay/XACK matrix, truthful lag negotiation and zero residual Streams passed |
| DB-KAFKA-001 | Messaging | Kafka API on Redpanda | Docker messaging | Ready | COMPLETE | `docs/test-evidence/kafka-redpanda.md` | `d2c88a2`, `de6b79e`; pure lag `UNSUPPORTED_CAPABILITY`, native committed-offset lag PASS, public topic delete/absence PASS |
| DB-RABBITMQ-001 | Messaging | AMQP + RabbitMQ management | Docker messaging | Ready | COMPLETE | `docs/test-evidence/rabbitmq.md` | `d2c88a2`, IF-T47/IF-T59; confirms, ACKs, exact detail, conditional delete and zero residual queues passed |
| DB-NATS-001 | Messaging | NATS Core + JetStream | Docker messaging | Ready | COMPLETE | `docs/test-evidence/nats.md` | `d2c88a2`; Core ephemeral and JetStream delete verified |
| DB-MQ-TLS-001 | Messaging | AMQPS + NATS TLS | Docker messaging-tls | Ready | COMPLETE | `docs/test-evidence/messaging-tls.md` | `d2c88a2`; regenerated CA-backed TLS passed |
| DB-KAFKA-VENDORS-001 | Messaging | AutoMQ/WarpStream/Confluent | external | Ready | EXTERNAL | - | no vendor DSNs are supplied |

## 2026-07-24 Support-Depth Audit

The product result above answers whether the named backend completed its
family checklist. The following matrix records the narrower method-level
boundaries found while re-auditing the current adapters and runners.

| Backend group | Supported depth | Explicitly unsupported or not yet proven |
| --- | --- | --- |
| SQLite, PostgreSQL, MySQL | bounded query/execute, schema/table metadata, typed values, bound parameters, atomic import/rollback, guarded cleanup | no current product gap |
| MariaDB, TiDB, CockroachDB, TimescaleDB | named-product CRUD, catalogs, typed values, bounds, guarded cleanup and atomic import/rollback; direct bound-parameter product tests are now wired into each Docker runner | MariaDB exposes its `JSON` alias as lossless bytes over the MySQL wire protocol rather than native `MYSQL_TYPE_JSON`; the client does not guess that arbitrary bytes are JSON |
| SQL Server | bounded generic SQL CRUD/catalog/type operations and guarded cleanup | dynamic parameters and atomic row import are not advertised; local Apple Silicon cannot run the x86_64-only product image |
| Redshift | PostgreSQL-compatible adapter and external CRUD/type runner exist | live product proof, atomic import and rollback remain external until `DBTOOL_IT_REDSHIFT_DSN` is supplied |
| Cassandra, ScyllaDB | native CQL plus SQL-compatible CRUD, schema/primary-key metadata, typed values, bounds, guarded cleanup | dynamic parameters are not advertised; current product evidence is single-node |
| IBM Db2 | adapter, bounded catalogs, CLI surface and service-free exact-budget tests | live SQL/catalog lifecycle is blocked on a supported host-installed IBM 64-bit client |
| Redis, Valkey, KeyDB, Dragonfly | binary-safe KV reads, TTL/restore, strict SCAN, allowlisted raw commands, exact guarded mutations and cleanup | consumer lag is runtime/product dependent; KeyDB 6.3 does not advertise it |
| MongoDB | bounded find/aggregate, exact one/many mutations, `$out`/`$merge`, collection drop and cleanup | no current product gap |
| OpenSearch, Elasticsearch | plain HTTP exact search CRUD, bounded reads/catalogs and guarded index cleanup; OpenSearch security-plugin HTTPS and Elasticsearch X-Pack HTTPS/auth/CA are product-tested | index catalog bounds are client/transport bounds, not server cursor pagination |
| Prometheus | bounded metric catalog/range query and guarded remote write | public update/delete are not part of the Prometheus model; cleanup uses an integration-only admin path |
| VictoriaMetrics | named-product `victoriametrics://` routing, bounded metric catalog/range query and guarded Prometheus remote write | native import/export, multitenancy, clustering and authenticated `vmauth` routing are not implemented or claimed |
| Redis messaging, Kafka/Redpanda, AMQP/RabbitMQ, NATS | bounded produce/consume, protocol-appropriate ACK/group/admin operations and guarded cleanup; AMQPS and NATS TLS are live-tested | pure Kafka has no group lag; direct AMQP has no portable queue catalog; NATS Core has no durable admin catalog; RabbitMQ management HTTPS is not implemented |
| AutoMQ, WarpStream, Confluent | native Kafka runner and alias routing exist | product endpoints are external; live evidence must separately prove metadata/cursor fidelity for every supplied vendor |

### Depth-Gap Task Queue

| Task | Priority | Status | Gap / implementation | Verification gate |
| --- | --- | --- | --- | --- |
| DB-GAP-SERVER-TIMEOUT-001 | P0 | VERIFIED | server lock-timeout tests expected retryable `QUERY_ERROR` after mutation dispatch; updated PostgreSQL/MySQL assertions to the non-retryable `OUTCOME_INDETERMINATE` contract | `server-timeout` Docker phase PASS |
| DB-GAP-FIXTURE-CONTRACT-001 | P0 | VERIFIED | Redis/Cassandra fixture scripts used pre-v2 raw-array assertions and fixture-image checks used stale resource names | `fixture-data`, `data-roundtrip`, `fixture-images`, and `cassandra-fixture` Docker phases PASS |
| DB-GAP-SQL-PARAM-ALIASES-001 | P1 | VERIFIED | MariaDB/TiDB/CockroachDB/TimescaleDB inherited parameter support without direct named-product coverage | six direct `live_sql_params` product tests PASS across base/compat/pg-compat/tidb |
| DB-GAP-MARIADB-JSON-TYPE-001 | P2 | PROTOCOL_BOUNDARY | MariaDB reports its `JSON` alias as LONGTEXT/binary over the MySQL protocol, so the adapter preserves exact bytes rather than guessing from content | direct parameter test parses the preserved bytes and proves exact JSON content; a future typed upgrade needs reliable origin/schema metadata |
| DB-GAP-KV-EXACT-ALIASES-001 | P1 | VERIFIED | Valkey/KeyDB/Dragonfly had not rerun the latest exact mutation input-budget contract | focused adapter exact-mutation test PASS 1/1 against each compatible product |
| DB-GAP-RABBITMQ-MANAGEMENT-RACE-001 | P1 | VERIFIED | an AMQP-declared queue can briefly be absent from the management API before its statistics fields appear | retry only transient HTTP 404 and missing-statistics shapes; full messaging phase PASS |
| DB-GAP-KAFKA-VENDOR-FIDELITY-001 | P1 | HARNESS_READY / EXTERNAL | vendor smoke skipped key/header/partition/timestamp fidelity | metadata verification is now mandatory; supply each vendor DSN for separate live evidence |
| DB-GAP-ELASTICSEARCH-HTTPS-001 | P1 | VERIFIED | `elasticsearch+https://` previously had only service-free and shared TLS harness coverage | Elasticsearch 8.15.5 X-Pack HTTPS/basic-auth CRUD, bad-auth, missing-CA and cleanup PASS |
| DB-GAP-RABBITMQ-MANAGEMENT-HTTPS-001 | P2 | NOT_IMPLEMENTED | `rabbitmq+http://` is admin-only and management TLS has no registered scheme/transport | implement `rabbitmq+https://` without weakening CA/auth validation, then add live management CRUD proof |
| DB-GAP-LOCAL-RESOURCE-LANES-001 | P2 | VERIFIED | `heavy/all` mixed runnable single-service phases with TiDB HA, x86_64-only and external phases; `local-heavy` now selects only serial 2-CPU/8-GiB-safe product phases | exact dry-run inventory plus every selected local product phase PASS |
| DB-GAP-ETCD-001 | P1 | RESEARCHED / NOT_IMPLEMENTED | no `etcd://` factory; Range/Put/DeleteRange/Txn/Watch and auth-token semantics require a new exact KV contract rather than a Redis alias | implement service-free base64/transaction budgets, then run a pinned etcd 3.6 product lifecycle |
| DB-GAP-INFLUXDB2-001 | P2 | RESEARCHED / NOT_IMPLEMENTED | no `influxdb://` factory; org/bucket/token initialization and Flux query responses do not fit the Prometheus adapter directly | define explicit bucket/write/query capabilities, pin a 2.9.x image, and prove auth plus disposable-bucket cleanup |
| DB-GAP-PULSAR-001 | P2 | RESEARCHED / NOT_IMPLEMENTED | no Pulsar factory or Rust client dependency; broker semantics include ACK, backlog and topic/subscription cleanup | dependency/API review first, then a resource-budgeted standalone Docker lifecycle |
| DB-GAP-MQTT-001 | P3 | RESEARCHED / NOT_IMPLEMENTED | no MQTT factory; QoS ACK is protocol-level, lag is not offset-based, and topics are not durable admin resources | define a truthful publish/subscribe-only capability subset before selecting a client |
| DB-GAP-ROCKETMQ-001 | P3 | RESEARCHED / NOT_IMPLEMENTED | no RocketMQ factory and no Apache-maintained Rust client was found; official admin semantics are deeper than current transport options | choose a maintained client or a bounded bridge before adding any scheme |

Current campaign details and honest non-pass boundaries are recorded in
[`support-depth-audit-2026-07-24.md`](test-evidence/support-depth-audit-2026-07-24.md).

## Per-Resource Evidence Contract

Every `LIVE_PASS` evidence file under `docs/test-evidence/` contains one row per
fixture resource:

| Resource | Create | Insert/write | Read all fixture data | Update/overwrite | Targeted delete | Metadata/admin | Guard | Limit/timeout | Cleanup |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| `dbtool_it_*` | PASS/N/A | PASS/N/A | expected and actual row/key/document/message counts plus stable IDs | PASS/N/A/UNSUPPORTED | PASS/N/A/UNSUPPORTED | PASS/N/A | PASS | PASS/N/A | PASS/UNSUPPORTED |

The evidence must also record the exact runner, UTC timestamp, image/product
version, architecture, result, and any unsupported capability boundary.

The cross-family final live inventory is recorded in
[`final-residue-audit.md`](test-evidence/final-residue-audit.md). It reports
zero per-run SQL tables, Redis keys, Mongo collections, Search indices,
Prometheus series, Kafka topics, RabbitMQ queues, and NATS JetStream state; the
configured Cassandra harness keyspace remains with zero tables.

## Design-Only, Not Registered

Oracle, etcd, InfluxDB, Pulsar, MQTT, and RocketMQ still appear as design
candidates in `dbtool-design.md`, but no factory is registered for them. They
are not counted as current support and cannot be marked tested. VictoriaMetrics
left this list only after its named scheme and real product lifecycle passed;
that support remains limited to its Prometheus-compatible API.

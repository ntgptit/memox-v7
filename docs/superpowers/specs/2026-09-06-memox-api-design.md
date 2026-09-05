# MemoX API independent backend design

| | |
|---|---|
| **Status** | draft |
| **Purpose** | Define the phased, independent Spring Boot API before it is integrated with the Flutter application. |
| **Scope** | PostgreSQL persistence, HTTP contract and every server-owned MemoX business flow; excludes authentication, synchronization and device-only side effects. |
| **Source of truth for** | Backend module seams, implementation phases, Flutter-to-backend behavior mapping and backend exclusions. |
| **Depends on** | `document-conventions.md` · `product.md` · `architecture.md` (AD-01) · `business-rules.md` · `data-model.md` · `use-cases.md` |
| **Updated by task** | M9 API foundation |
| **Last updated** | 2026-09-06 |

## Decision

`memox-api` is an independent Spring Boot 3 / Java 17 service backed by its
own PostgreSQL database.  It does not read, write, import, or synchronize a
Flutter SQLite database.  Flutter remains unchanged until this service has a
stable, tested OpenAPI contract.

The API is intentionally unauthenticated in this delivery.  It has no user,
token, session, authorization, synchronization, conflict-resolution, version
or pending-sync model.  Device-only work also remains out of scope: Android
notification scheduling, file picker UI and share-sheet UI.  Where the product
has persisted settings or a content-transfer behavior, the server exposes the
data or HTTP transfer operation without a device side effect.

## Configuration and operations

Configuration is the first phase.  No credential is committed to the
repository.  The local profile reads:

| Variable | Local value |
|---|---|
| `MEMOX_DB_URL` | `jdbc:postgresql://localhost:5432/memox` |
| `MEMOX_DB_USERNAME` | `giapnt` |
| `MEMOX_DB_PASSWORD` | supplied only in the local environment |

`application-local.properties`, `application-test.properties`, and
`application-prod.properties` provide profile-specific behavior.  Production
requires all database variables and fails fast when one is missing.  Tests use
an isolated PostgreSQL instance, never the developer's `memox` database.

Flyway owns all production schema changes under
`src/main/resources/db/migration/`; applied migrations are immutable.  MyBatis
mapper interfaces are paired one-to-one with `*_mapper.xml` files.  SQL never
lives in annotations.

## Module seams

Each feature module follows one request seam:

```
HTTP controller -> application service -> MyBatis mapper/XML -> PostgreSQL
```

Controllers parse and validate HTTP DTOs, delegate once, and select status
codes.  Application services own transactions and business rules that need
the current database state.  Mappers own PostgreSQL access only.  Request and
response DTOs never expose persistence rows.

| Module | Server responsibilities | Flutter reference |
|---|---|---|
| `deck` | hierarchy, scheduler choice/reset, move, reorder, trash | `lib/features/deck/` and `queries/deck.drift` |
| `card` | card CRUD, flag, tags, bulk move/delete, import/export | `lib/features/card/` and `queries/card.drift` |
| `study` | SRS queue, sessions, answers, histories and generation checks | `lib/features/study/` and `queries/study.drift` |
| `tag` | catalog, rename/merge, delete and filtering | `lib/features/card/` and `queries/tag.drift` |
| `search` | library search and keyset pagination | `lib/features/search/` and `queries/search.drift` |
| `progress` | overview and per-deck activity reads | `lib/features/progress/` and `queries/progress.drift` |
| `settings` | persisted global settings only | `lib/features/settings/` and `queries/settings.drift` |
| `trash` | soft-delete, restore, retention and purge | `lib/features/trash/` and `queries/trash.drift` |

The Flutter domain repositories and their tests are the behavior source.  The
Drift table definitions are the schema source.  They are not code-generation
input: SQLite-specific syntax such as `INSERT OR IGNORE`, `GROUP_CONCAT`,
`json_group_array`, boolean expressions and recursive CTE details are ported
deliberately to PostgreSQL. The automated backend suite uses isolated H2 in
PostgreSQL compatibility mode; PostgreSQL-specific behavior is validated during
local runtime checks against the configured PostgreSQL database.

## HTTP contract

All resource endpoints live under `/api/v1`.  IDs are UUID strings and times
are UTC ISO-8601 instants.  The server accepts client-supplied IDs so future
offline creation can synchronize without ID replacement, but it does not add
sync behavior in this delivery.

Every non-2xx response uses RFC 9457 `application/problem+json`, produced by
one `@RestControllerAdvice`.  `code` is a stable machine value, such as
`DECK_DEPTH_EXCEEDED`; validation problems include field paths.  Server text
is diagnostic, not Flutter UI copy.

Springdoc generates the runtime OpenAPI document.  A canonical exported
OpenAPI JSON file is committed and diffed in CI so code changes cannot silently
change the API contract.  Paginated responses state their `limit`,
`offset`, ordering and stable tie-breaker explicitly.

## Delivery phases

### Phase 0 — configuration and verification

- Establish profiles, environment-backed datasource configuration, Hikari,
  Flyway, MyBatis, Actuator health and an isolated H2 test setup.
- Add a failing startup/configuration test before implementation and prove local
  startup against the configured PostgreSQL database.

### Phase 1 — contract and baseline schema

- Define the common Problem Details response, OpenAPI export check and
  controller test harness.
- Port the complete persisted MemoX schema through an initial Flyway migration,
  including constraints and indexes defined in `docs/data-model.md`.
- Add migration and mapper/XML alignment tests against H2 in PostgreSQL
  compatibility mode.

### Phase 2 — library writes

- Deliver Deck, Card, Tag and Trash vertical slices, each with controller,
  application-service, mapper/XML and H2 integration tests.
- Port transactional rules such as maximum deck depth, content-type locking,
  subtree move rejection, delete/restore and tag merge from their Flutter
  repositories.

### Phase 3 — study engine

- Deliver scheduler selection/reset, study queues, session lifecycle, answer
  recording and append-only history.
- Reject stale scheduler-generation writes in the service transaction and
  test every scheduler action set.

### Phase 4 — query and transfer capabilities

- Deliver search, progress, persisted settings and server-owned card
  import/export.
- Use whitelist-based sorting and deterministic `limit`/`offset` pagination.

### Phase 5 — hardening

- Add full HTTP contract tests, H2 query semantics coverage, exported
  OpenAPI diff verification, production profile validation and CI wiring.
- Run all migrations from an empty PostgreSQL database and verify no endpoint
  logs card content, notes, history or transfer payloads.

## Testing strategy

Every behavior begins with a failing test.  Tests are layered:

| Layer | Proves |
|---|---|
| Controller | route, request validation, status code and Problem Details payload |
| Application service | business-rule success and failure behavior, including transaction boundaries |
| MyBatis/PostgreSQL | mapper/XML binding, SQL semantics, constraints, CTEs and index-sensitive reads |
| Flyway | clean-database migration and schema compatibility |
| Contract | exported OpenAPI matches the committed artifact |

The API does not claim Flutter integration is complete until a later task adds
a Flutter remote adapter and sync policy.  This design deliberately prevents
that integration from changing Flutter domain or presentation contracts.

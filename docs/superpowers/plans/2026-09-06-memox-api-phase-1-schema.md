# MemoX API Phase 1 Schema Implementation Plan

| | |
|---|---|
| **Status** | complete |
| **Purpose** | Port the frozen MemoX persisted model into a server-owned relational schema before resource endpoints are added. |
| **Scope** | PostgreSQL Flyway migration, H2 test migration, mapper schema smoke tests and migration documentation. |
| **Source of truth for** | Exact execution steps for MemoX API Phase 1 schema work. |
| **Depends on** | `docs/data-model.md` · `docs/superpowers/specs/2026-09-06-memox-api-design.md` · `docs/superpowers/plans/2026-09-06-memox-api-phase-0-foundation.md` |
| **Updated by task** | M9 API Phase 1 |
| **Last updated** | 2026-09-06 |

## 5Why

1. Why port the schema before endpoints? Resource behavior relies on database
   constraints, relationships and indexes that must be atomic before a service
   can safely mutate them.
2. Why mirror the Flutter schema rather than design a smaller server model?
   `docs/data-model.md` is frozen for MVP and the Flutter tables are the
   product's persisted behavior source.
3. Why retain client-generated string IDs? The independent backend must accept
   future offline-created IDs without server-side replacement, while sync itself
   remains out of scope.
4. Why have a separate H2 migration? Production migrations use PostgreSQL
   dialect features; the user requires isolated H2 tests, so its equivalent DDL
   must not alter checksums of migrations already applied to local PostgreSQL.
5. Why test the complete table surface now? A partial schema can make a mapper
   look healthy while the next feature fails at startup; a schema test exposes
   missing tables and the required singleton settings seed before services exist.

## Decision

Add version 2 migrations that create `decks`, `cards`, `card_study_states`,
`tags`, `card_tags`, `app_settings`, `delete_batches`, `study_sessions`,
`study_answers` and `study_queue_items`, with the constraints and indexes from
`docs/data-model.md`. PostgreSQL is the runtime schema. H2 uses a test-only
equivalent migration and never replaces or validates against the PostgreSQL
migration checksum.

## Task 1: Prove the complete schema is absent

**Files:**

- Modify: `memox-api/src/test/java/com/memox/migration/FlywayMigrationTest.java`

Write a failing H2 integration assertion that every Phase 1 table exists and
that `app_settings` contains only its seeded row with `id = 1`.

Run: `./mvnw.cmd -Dtest=FlywayMigrationTest test`

Expected: FAIL because only `api_metadata` exists.

## Task 2: Add PostgreSQL and H2 migrations

**Files:**

- Create: `memox-api/src/main/resources/db/migration/V2__create_memox_schema.sql`
- Create: `memox-api/src/test/resources/db/test-migration/V2__create_memox_schema.sql`

Port every table, check constraint, foreign-key cascade and index from the
frozen data model. Use `TIMESTAMPTZ` in PostgreSQL and `TIMESTAMP WITH TIME
ZONE` in H2. Seed the singleton `app_settings` row in both migrations.

## Task 3: Verify the migration contract

Run:

```text
./mvnw.cmd test
py -3 .claude/skills/flutter-workflow/scripts/check_docs.py --quiet
```

Expected: all backend tests use H2 and pass; the document contract remains
valid. Validate the same migration against local PostgreSQL before adding
endpoint work.

## Definition of Done

- PostgreSQL local runtime and H2 tests use their own dialect-safe migrations.
- The complete MVP persisted table surface, indexes and singleton settings row
  are verified by test.
- No auth, synchronization or device-only effect is introduced.

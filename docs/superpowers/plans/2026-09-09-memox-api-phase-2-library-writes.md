# MemoX API Phase 2 Library Writes Implementation Plan

| | |
|---|---|
| **Status** | draft, revised 2026-09-10 after M9.W1–W3 |
| **Purpose** | Port the 69 Drift library queries (deck · card · tag · trash) to MyBatis PostgreSQL statements and build the vertical slices that call them. |
| **Scope** | `memox-api` deck, card, tag and trash modules: mapper XML, mapper interfaces, domain records, application services, controllers, DTOs and their tests; plus the two migrations and one test-harness change those slices require. |
| **Source of truth for** | Exact execution steps for MemoX API Phase 2, and the Drift→MyBatis statement mapping for the four library modules. |
| **Depends on** | `docs/superpowers/specs/2026-09-06-memox-api-design.md` · `docs/business-rules.md` · `docs/data-model.md` · `docs/superpowers/plans/2026-09-06-memox-api-phase-1-schema.md` |
| **Updated by task** | M9 API Phase 2 |
| **Last updated** | 2026-09-10 |

> **For agentic workers:** REQUIRED SUB-SKILL: Use `superpowers:subagent-driven-development` (recommended) or `superpowers:executing-plans` to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Every library behaviour the Flutter app performs against SQLite — reading the deck tree with its counts, listing and filtering cards, managing the tag catalog, and soft-delete / restore / purge — is available over `/api/v1` against PostgreSQL, with the same business rules enforced inside the same transaction.

**Architecture:** One seam per request: `HTTP controller → application service → MyBatis mapper/XML → PostgreSQL`. Controllers validate DTOs, delegate once and choose a status code. Services own the transaction and every rule that needs the data as it stands at the moment of writing. Mappers own SQL only, and all SQL lives in `*_mapper.xml`. The Drift `.drift` files are the **behaviour** source, not code-generation input: SQLite syntax is translated deliberately, statement by statement, under the contract in §2.

**Tech Stack:** Java 17, Spring Boot 3.5, MyBatis (XML mappers), Flyway, PostgreSQL 16/17, Testcontainers *or* a local PostgreSQL test database (see Task 0), JUnit 5, AssertJ, ArchUnit, springdoc-openapi, Lombok.

## 0. What changed under this plan before it ran

This plan was written on 2026-09-09, before three standardisation waves landed. **The code moved; a
plan that still describes the old code is not a neutral document — it is confidently wrong, and it
reads as authoritative.** Every task below has been corrected. What changed, and what it means for
the steps you are about to follow:

| Landed | What it invalidated here | Now |
|---|---|---|
| **M9.W1** (#512) — CI gate, static analysis, coverage floor, dual-backend Postgres harness, `openapi.json` snapshot | Task 0's whole design; Task 15's assumption that no snapshot exists | Task 0 is history, Task 15 regenerates the snapshot |
| **M9.W2** (#513) — `<feature>/api` → `controller` + `dto/{request,response}`, `<feature>/domain` → `entity` + `enums` + `exception` | **Every `Files:` path in Tasks 2–15** — 30 of them | Rewritten. A closed-world ArchUnit rule now fails any class outside the layout, so the old paths cannot be recreated quietly |
| **M9.W3** (#514) — `page`/`size` paging, `PageQuery<TSort>`, `SortSpec`, `SortField`, `PageSlice`, `SortSpecs` | The `#{pageQuery.limit}` XML in Tasks 2 and 7, the `limit=&offset=` endpoint docs, and `CardSort` | Ported statements take `@Param("slice") PageSlice`; sort is an enum whitelist, not a string |
| **Phase 2 prep** (this revision) | Task 0's `MemoxFixtures`, Task 1's handler, Task 5's migration, Task 15's architecture rules | All landed early — see the notes on each task |

**New shared infrastructure you should use rather than reinvent:**

- **`MemoxFixtures`** — the seeding vocabulary, reachable unqualified from any test extending
  `PostgresIntegrationTest`. It writes through `JdbcTemplate` and maintains no invariants on
  purpose, so it can place rows a service would refuse to place.
- **`AffectedRows.requireExactlyOne(rows, supplier)`** — *use this on every UPDATE and DELETE in
  Tasks 6, 9, 10, 12 and 13.* Discarding a mapper's row count makes a write that matched nothing
  look exactly like one that succeeded. Zero rows raises the exception the caller supplies (the
  feature's not-found or conflict); more than one is always an `IllegalStateException`, because a
  single-row write that matched several has a defective WHERE clause and that is never a client's
  fault.
- **`PageHelper.slice(pageQuery, defaultSorts, tieBreaker)` → `PageSlice`** — every list statement
  goes through it. It appends the tie-breaker automatically, which LIMIT/OFFSET needs and which is
  otherwise forgotten once per endpoint. **A query with table aliases must give its sort enum the
  qualified column** (`d.sibling_position`, not `sibling_position`), because the rendered
  `ORDER BY` is inserted verbatim.
- **`V5__defer_deck_sibling_position.sql`** — already applied, so Task 5 no longer creates it.

**Still not built, deliberately:** `IdCollections` (no caller yet — see Task 1) and the
`search` field of the shared paging contract (no statement searches yet; publishing a parameter the
SQL ignores lets a client filter, get everything back, and never know).

**Spec:** `docs/superpowers/specs/2026-09-06-memox-api-design.md`

---

## Global Constraints

- API paths start with `/api/v1`. IDs are client-supplied UUID strings. Times are `Instant`, rendered as UTC ISO-8601.
- **SQL belongs only in `src/main/resources/mybatis/**/*_mapper.xml`.** MyBatis annotation SQL is forbidden. One mapper interface pairs one-to-one with one XML file.
- Flyway owns every schema change under `src/main/resources/db/migration/`. **Applied migrations are immutable** — `V1`…`V4` are already applied locally and MUST NOT be edited. New work adds `V5`, `V6`, …
- Every non-2xx response is RFC 9457 `application/problem+json` produced by the single `@RestControllerAdvice` in `com.memox.common.error.ApiExceptionHandler`. Every new failure gets an `ApiErrorCode` constant **and** an entry in both `messages.properties` and `messages_vi.properties`.
- Auth, sync, and device-only side effects stay out of scope. `owner_id` columns exist and are always `NULL` in this phase; queries that Drift scopes with `owner_id IS :ownerId` are ported with the scope predicate present and bound to `null`, so adding auth later is a binding change and not a query rewrite.
- **Never log card content, note text, tag names, history or transfer payloads at any level** (BR-51, BR-52, BR-267). Diagnostics carry IDs and counts.
- Every production behaviour is introduced by a failing test, then the minimum code, then a passing test. Commit at the end of each task.
- `flutter`-side files are **not** touched by this plan. `lib/` is read-only reference.
- Java style follows the existing code: tab indentation, `final var` locals, records for domain and DTOs, `@RequiredArgsConstructor` for Spring beans, constructor-arg `resultMap`s in XML.

**One place this plan knowingly departs from the spec.** The spec's Phase 2 text says integration tests run "against H2 in PostgreSQL compatibility mode". The code has already moved past that: there is no `src/test/resources/db/test-migration/` any more, `V2`…`V4` are PostgreSQL-only (`TIMESTAMPTZ`, partial unique index on `COALESCE(owner_id, '')`), and `PostgresTestcontainersConfiguration` runs a real `postgres:16-alpine`. Half the statements in this plan — `string_agg`, `json_agg`, row-value comparison, `DEFERRABLE` constraints, `strpos` — are exactly the ones H2's compatibility mode gets wrong or refuses, so testing them on H2 would prove nothing about production. This plan tests on PostgreSQL. **The spec paragraph is now stale and should be corrected in a separate documentation task**, not edited in passing here.

---

## 1. Query inventory — all 69 statements and where each lands

`lib/core/database/queries/` holds **102** named Drift queries in nine files. This plan ports the **69** belonging to the four library modules. The remaining 33 are Phase 3/4 and are listed in §7.

### deck.drift → `deck_mapper.xml` (17)

| Drift query | MyBatis statement | Task |
|---|---|---|
| `rootDecks` | `findRootDecks` *(exists)* | — |
| `rootDeckSummaries` | `findRootDeckSummaries` | 2 |
| `allDecks` | `findAllActiveDecks` | 2 |
| `deckById` | `findActiveDeckById` *(exists)* | — |
| `decksInTree` | `findDecksInTree` | 2 |
| `childDeckLevel` | `findChildDeckLevel` | 3 |
| `nextSiblingPosition` | `nextSiblingPosition` *(exists, scope-based)* | — |
| `siblingDecks` | `findSiblingDecksForUpdate` | 5 |
| `cardMoveTargets` | `findCardMoveTargets` | 6 |
| `subtreeDeckIds` | `findSubtreeDeckIds` | 4 |
| `deckDepthProbe` | `probeDeckDepth` | 4 |
| `subtreeHeightProbe` | `probeSubtreeHeight` | 4 |
| `directChildDeckCount` | `countDirectChildDecks` | 4 |
| `directCardCount` | `countDirectCards` | 4 |
| `subtreeCardCount` | `countSubtreeCards` | 4 |
| `updateSubtreeRootDeck` | `updateSubtreeRootDeck` | 6 |
| `resetTreeStudyStates` | — | **deferred to Phase 3** (§7) |

### card.drift → `card_mapper.xml` (22)

| Drift query | MyBatis statement | Task |
|---|---|---|
| `cardsByDeck` | `findActiveCardsByDeck` *(exists)* | — |
| `cardListItems` | `findCardListItems` | 7 |
| `cardCount` | `countCardListItems` | 7 |
| `cardIdsMatching` | `findCardIdsMatching` | 7 |
| `cardById` | `findActiveCardById` | 8 |
| `cardDetailById` | `findCardDetailById` | 8 |
| `studyStateByCard` | `findStudyStateByCard` | 8 |
| `cardHistoryFirstPage` | `findCardHistoryFirstPage` | 8 |
| `cardHistoryAfter` | `findCardHistoryAfter` | 8 |
| `flaggedCardsByDeck` | `findFlaggedCardsByDeck` | 7 |
| `cardStateCountsByDeck` | `countCardStatesByDeck` | 7 |
| `deckContextById` | `findDeckContextById` | 3 |
| `cardDeckContextForIds` | `findCardDeckContextForIds` | 9 |
| `moveCardsToDeck` | `moveCardsToDeck` | 9 |
| `setCardsFlagByIds` | `setCardsFlagByIds` | 9 |
| `tagCountsForCards` | `countTagsForCards` | 10 |
| `cardsAlreadyTagged` | `findCardsAlreadyTagged` | 10 |
| `cardKeysInDeck` | `findCardKeysInDeck` | 11 |
| `tagsByFoldedNames` | `findTagsByFoldedNames` | 10 |
| `exportDeckName` | `findExportDeckName` | 11 |
| `exportCardsInDeck` | `findExportCardsInDeck` | 11 |
| `exportCardsByIds` | `findExportCardsByIds` | 11 |

### tag.drift → `tag_mapper.xml` (13)

| Drift query | MyBatis statement | Task |
|---|---|---|
| `tagByFoldedName` | `findTagByFoldedName` | 10 |
| `allTags` | `findAllTags` | 10 |
| `tagsForCard` | `findTagsForCard` | 10 |
| `tagsForCards` | `findTagsForCards` | 10 |
| `tagCountForCard` | `countTagsForCard` | 10 |
| `tagCatalog` | `findTagCatalog` | 10 |
| `tagById` | `findTagById` | 10 |
| `tagCardCount` | `countCardsForTag` | 10 |
| `renameTagById` | `renameTagById` | 10 |
| `linkCardsOfTagTo` | `linkCardsOfTagTo` | 10 |
| `unlinkAllCardsFromTag` | `unlinkAllCardsFromTag` | 10 |
| `deleteTagById` | `deleteTagById` | 10 |
| `orphanedTags` | `findOrphanedTags` | 10 |

### trash.drift → `trash_mapper.xml` (17)

| Drift query | MyBatis statement | Task |
|---|---|---|
| `activeSubtreeDeckIds` | `findActiveSubtreeDeckIds` | 12 |
| `activeCardIdsInDecks` | `findActiveCardIdsInDecks` | 12 |
| `markDecksDeleted` | `markDecksDeleted` | 12 |
| `markCardsDeleted` | `markCardsDeleted` | 12 |
| `trashBatchRows` | `findTrashBatchRows` | 13 |
| `batchById` | `findBatchById` | 13 |
| `batchDeckIds` | `findBatchDeckIds` | 13 |
| `batchCardIds` | `findBatchCardIds` | 13 |
| `tombstoneDeckInBatch` | `findTombstoneDeckInBatch` | 13 |
| `tombstoneCardInBatch` | `findTombstoneCardInBatch` | 13 |
| `anyDeckById` | `findAnyDeckById` | 13 |
| `batchSubtreeHeightProbe` | `probeBatchSubtreeHeight` | 13 |
| `restoreDecksInBatch` | `restoreDecksInBatch` | 13 |
| `restoreCardsInBatch` | `restoreCardsInBatch` | 13 |
| `eligibleBatches` | `findEligibleBatches` | 14 |
| `purgeBlockerCount` | `countPurgeBlockers` | 14 |
| `purgeBatch` | `purgeBatch` | 14 |

---

## 2. SQLite → PostgreSQL translation contract

Every ported statement obeys this table. It is the reusable core of the whole plan: get it wrong once and 69 statements repeat the mistake. Task 1 turns rows 1–4 and 9 into executable helpers and a test; every later task cites the row it applied.

| # | SQLite / Drift | PostgreSQL | Why it is not a straight copy |
|---|---|---|---|
| 1 | `GROUP_CONCAT(t.name, char(31))` | `string_agg(t.name, chr(31) ORDER BY t.name, t.id)` | `GROUP_CONCAT` has **no defined order** in SQLite; `string_agg` has none either unless you give it one. Tag strings that reorder between two reads make the Flutter list flicker and make a golden untestable. The explicit `ORDER BY` is the fix, and it matches `tagsForCard`'s own ordering. |
| 2 | `json_group_array(json_object('id', …))` | `COALESCE(json_agg(json_build_object('id', …)), '[]'::json)` | SQLite returns `[]` for an empty set; PostgreSQL returns `NULL`. Without the `COALESCE`, an ancestry path for a level-1 deck deserialises to `null` instead of an empty list and the client's `List<Ancestor>` parse throws. |
| 3 | `INSERT OR IGNORE INTO card_tags …` | `INSERT INTO card_tags … ON CONFLICT (card_id, tag_id) DO NOTHING` | Tag merge (BR-234) links every card of the source tag to the target; cards already carrying both must not fail the batch. |
| 4 | `instr(t.name_folded, :searchFolded) > 0` | `strpos(t.name_folded, #{searchFolded}) > 0` | `instr` does not exist in PostgreSQL. `strpos` has the same 1-based / 0-for-absent contract. |
| 5 | `WHERE parent_deck_id IS :parentDeckId` | `WHERE sibling_scope_id = #{siblingScopeId}` for positions; `WHERE owner_id IS NOT DISTINCT FROM #{ownerId}` elsewhere | SQLite's `IS` is a null-safe compare; `=` in PostgreSQL is not. For **sibling scope** the server already resolved this differently and better: `V3` added `sibling_scope_id` (roots use the all-zero sentinel `DeckPositionScope.ROOT_DECKS`) plus `UNIQUE (sibling_scope_id, sibling_position)`. Use the scope column there; use `IS NOT DISTINCT FROM` for `owner_id`, which has no such column. |
| 6 | `is_flagged INTEGER … = 1` | `is_flagged SMALLINT … = 1`, bound as `int` | Reading works (`getBoolean` on a smallint yields 0→false/1→true), but **binding a Java `boolean` into a smallint column fails**: `column "is_flagged" is of type smallint but expression is of type boolean`. Task 1 adds one `BooleanSmallIntTypeHandler` so both directions go through one place. |
| 7 | `SELECT parent_id IS NULL AS reachedRoot` | same text, but the column is `boolean` not `0/1` | Map it to `Boolean` in the result record, not `int`. |
| 8 | `ORDER BY t.name ASC` | `ORDER BY t.name_folded ASC, t.id ASC` (already what `tagCatalog` does) | SQLite compares `TEXT` byte-wise; PostgreSQL uses the database collation, so `"Ánh"` vs `"anh"` can order differently. Ordering by the folded column removes the disagreement, and the `id` tie-break makes the page boundary stable. Where Drift orders by raw `name` (`allTags`, `tagsForCard`), keep `name` **and** add `id` — the difference is presentation ordering only, and the tie-break is what pagination needs. |
| 9 | `WHERE id IN :cardIds` | `<foreach collection="cardIds" open="(" separator="," close=")" item="cardId">#{cardId}</foreach>` | PostgreSQL rejects `IN ()`. Every `IN`-collection statement is guarded so an **empty collection never reaches the database** — the service returns early. Task 1's test pins this. |
| 10 | `WITH RECURSIVE x (a) AS (SELECT … UNION SELECT …)` | identical | PostgreSQL supports the same form. Two constraints it adds and SQLite does not: the recursive term may reference the CTE **once**, and may not contain `LIMIT`. No ported query violates either. Referencing the CTE from the outer query (as `childDeckLevel` does, in a scalar sub-select and in a `LEFT JOIN`) is fine. |
| 11 | `DATETIME` | `TIMESTAMPTZ` | Bind `java.time.Instant`. Never call `now()` / `CURRENT_TIMESTAMP` inside a statement — the clock is `java.time.Clock` from `TimeConfiguration`, so a test can pin it. |
| 12 | `SUM(CASE WHEN … THEN 1 ELSE 0 END)` over an empty group | returns `NULL` in both | Keep the existing `COALESCE(x, 0)` wrappers. |

---

## 3. File structure

New and changed files, grouped by responsibility. Each mapper XML stays under 400 lines; when a module's SQL outgrows that, split by aggregate (`deck_mapper.xml` + `deck_tree_mapper.xml`) rather than by statement type.

```
memox-api/src/main/
├─ java/com/memox/
│  ├─ common/mybatis/BooleanSmallIntTypeHandler.java        NEW  (row 6)
│  ├─ common/error/ApiErrorCode.java                        MOD  (+14 codes)
│  ├─ deck/
│  │  ├─ controller/ DeckController.java                                     MOD
│  │  ├─ dto/request/  RenameDeckRequest · MoveDeckRequest ·
│  │  │                ReorderDeckRequest                                    NEW
│  │  ├─ dto/response/ DeckSummaryResponse · DeckLevelResponse               NEW
│  │  ├─ entity/     DeckSummary · DeckLevelChild · DeckAncestor · DeckDepth ·
│  │  │              DeckCounts · DeckMoveTarget                             NEW
│  │  ├─ exception/  DeckReorderException                                    NEW
│  │  ├─ persistence/DeckMapper.java                                         MOD
│  │  └─ service/    DeckTreeService · DeckStructureService ·
│  │                 DeckMoveService · DeckLimits · RenameDeckCommand ·
│  │                 MoveDeckCommand · ReorderDeckCommand                    NEW
│  ├─ card/
│  │  ├─ controller/ CardController.java                                     MOD
│  │  ├─ dto/request/  UpdateCardRequest · BulkMoveRequest · BulkFlagRequest NEW
│  │  ├─ dto/response/ CardListResponse · CardDetailResponse ·
│  │  │                CardHistoryResponse · ExportResponse                  NEW
│  │  ├─ entity/     CardListItem · CardDetail · CardStudyState ·
│  │  │              CardHistoryEntry · CardStateCounts · CardFilter ·
│  │  │              ExportCard · CardKey                                    NEW
│  │  ├─ enums/      CardSortField                                     ALREADY EXISTS
│  │  ├─ persistence/CardMapper.java                                         MOD
│  │  └─ service/    CardQueryService · CardEditService · CardBulkService ·
│  │                 CardExportService · StageThresholds                     NEW
│  ├─ tag/           controller · dto/{request,response} · entity ·
│  │                 exception · persistence · service                       NEW module
│  └─ trash/         controller · dto/{request,response} · entity · enums ·
│                    exception · persistence · service                       NEW module
└─ resources/
   ├─ db/migration/V5__defer_deck_sibling_position.sql       NEW
   ├─ db/migration/V6__add_trash_indexes.sql                 NEW
   ├─ mybatis/deck_mapper.xml · card_mapper.xml              MOD
   ├─ mybatis/tag_mapper.xml · trash_mapper.xml              NEW
   └─ messages.properties · messages_vi.properties           MOD
```

---

## Task 0: Make the test suite runnable on this machine

> **DONE — and not the way this task describes.** Everything below was delivered by M9.W1
> (PR #512) and the Phase 2 prep commit, under different names and a better design. Read this
> section as history; do not execute it. What it asked for and what exists:
>
> | Task 0 asked for | What exists now |
> |---|---|
> | A local-Postgres escape from the Docker problem | `TestDatabaseBackends` + `LocalPostgresConfiguration`, chosen by `memox.test.database`; Docker Desktop is also installed now, so `testcontainers` is the working default |
> | A hand-listed truncate that reaches `tags` and `delete_batches` | `MemoxTestDataReset` reads `pg_catalog.pg_tables` instead, so **a table a future migration adds is reset the day it appears**. Re-implementing the hand-list would be a regression |
> | A `TestDataResetTest` | exists, and asserts the catalog-driven behaviour |
> | `MemoxFixtures` as a `protected final` field on `PostgresIntegrationTest` | exists as a **superclass**: `PostgresIntegrationTest extends MemoxFixtures`. Same unqualified call sites (`insertRootDeck(...)`), without 25 one-line delegating methods putting the fixture surface in two places. Covered by `MemoxFixturesTest` |
>
> **Still open from this task: nothing.** Start at Task 1.

**Why it existed:** `./mvnw test` on the worktree at the time was **32 tests, 21 errors**. Every error had the same root cause — `PostgresTestcontainersConfiguration` asked Testcontainers for `postgres:16-alpine` and Docker was not installed. Until that was fixed, no step in this plan could run its own verification, and TDD was impossible.

Two further defects in the harness were fixed with it, because the same file was being edited:

- `PostgresIntegrationTest.clearMemoXData` truncated only `decks CASCADE`. `tags`, `card_tags` and `delete_batches` have no FK path from `decks`, so **tag and trash rows leaked between tests** — every Task 9–14 test would have been order-dependent.
- `app_settings` is seeded by `V2` with `id = 1`; a `TRUNCATE … CASCADE` that ever reaches it removes the singleton row. The truncate list must exclude it.

**Files:**
- Create: `memox-api/src/test/java/com/memox/support/LocalPostgresConfiguration.java`
- Modify: `memox-api/src/test/java/com/memox/support/PostgresIntegrationTest.java`
- Modify: `memox-api/src/test/resources/application-test.properties`
- Modify: `memox-api/pom.xml`
- Create: `memox-api/src/test/java/com/memox/support/TestDataResetTest.java`
- Create: `memox-api/src/test/java/com/memox/support/MemoxFixtures.java`

**Interfaces:**
- Produces: `PostgresIntegrationTest` — abstract base every integration test extends. Resets all ten MemoX tables between tests and reseeds `app_settings`. Selected backend is chosen by the `memox.test.database` property: `testcontainers` (default, CI) or `local` (developer machines without Docker).
- Consumes: `MEMOX_TEST_DB_URL` / `MEMOX_TEST_DB_USERNAME` / `MEMOX_TEST_DB_PASSWORD` when `memox.test.database=local`.
- Produces: `MemoxFixtures` — the seeding vocabulary every later task's tests use, so no two tasks write two different "make me a deck" helpers. `PostgresIntegrationTest` exposes it as a `protected final MemoxFixtures fixtures` and re-exports the common calls as protected methods, which is why the tests in Tasks 2–14 read `insertRootDeck(...)` with no receiver. Exact signatures:

```java
void insertRootDeck(String id, String name);
void insertRootDeck(String id, String name, SchedulerType schedulerType);
void insertRootDeck(String id, String name, SchedulerType schedulerType, int generation);
void insertSubDeck(String id, String name, String parentId, String rootId);
void insertSubDeck(String id, String name, String parentId, String rootId, DeckContentType contentType);
void insertSubDeckAt(String id, String name, String parentId, String rootId, int siblingPosition);
void insertChain(int levels);                  // "d1".."dN", d1 is the root
void insertCardWithState(String id, String deckId, Instant learnedAt, Instant dueAt);
void insertFlaggedCard(String id, String deckId);
void insertTag(String id, String name);        // name_folded = name.trim().toLowerCase()
void linkTag(String cardId, String tagId);
void softDelete(String itemType, String itemId);   // creates a batch and stamps the one row
void backdateBatch(String batchId, Duration age);
void reviveDeckWithoutBatch(String deckId);
// readers used in assertions
String deckIdOf(String cardId);   String rootDeckIdOf(String deckId);
String batchIdOfDeck(String deckId);   String batchIdOfCard(String cardId);
DeckContentType contentTypeOf(String deckId);   int siblingPositionOf(String deckId);
boolean flaggedOf(String cardId);   boolean cardExists(String id);   boolean deckExists(String id);
boolean tagExists(String id);   List<String> tagIdsOf(String cardId);
```

`MemoxFixtures` writes through `JdbcTemplate`, never through the services under test — a fixture that calls the production write path cannot fail independently of it, and Task 12's "an earlier tombstone is not absorbed" test needs to place a tombstone the service would refuse to place.

- [ ] **Step 1: Write the failing test**

`memox-api/src/test/java/com/memox/support/TestDataResetTest.java`:

```java
package com.memox.support;

import static org.assertj.core.api.Assertions.assertThat;

import java.time.Instant;

import org.junit.jupiter.api.Test;

class TestDataResetTest extends PostgresIntegrationTest {

	@Test
	void removesTagAndTrashRowsBetweenTests() {
		jdbcTemplate.update("INSERT INTO tags (id, name, name_folded, created_at) VALUES (?, ?, ?, ?)",
				"11111111-1111-1111-1111-111111111111", "leak", "leak", Instant.now());
		jdbcTemplate.update("INSERT INTO delete_batches (id, item_type, root_item_id, deleted_at) VALUES (?, ?, ?, ?)",
				"22222222-2222-2222-2222-222222222222", "card", "33333333-3333-3333-3333-333333333333", Instant.now());

		resetMemoxData();

		assertThat(jdbcTemplate.queryForObject("SELECT COUNT(*) FROM tags", Long.class)).isZero();
		assertThat(jdbcTemplate.queryForObject("SELECT COUNT(*) FROM delete_batches", Long.class)).isZero();
		assertThat(jdbcTemplate.queryForObject("SELECT COUNT(*) FROM app_settings WHERE id = 1", Long.class)).isOne();
	}
}
```

- [ ] **Step 2: Run it and watch it fail for the right reason**

```bash
cd memox-api && ./mvnw.cmd -Dtest=TestDataResetTest test
```

Expected: FAIL — first with the Docker/context error, and after Step 3's datasource change, with `resetMemoxData()` not defined and `tags` still holding a row.

- [ ] **Step 3: Add the local-PostgreSQL backend**

`LocalPostgresConfiguration.java`:

```java
package com.memox.support;

import javax.sql.DataSource;

import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.boot.jdbc.DataSourceBuilder;
import org.springframework.boot.test.context.TestConfiguration;
import org.springframework.context.annotation.Bean;
import org.springframework.core.env.Environment;

@TestConfiguration(proxyBeanMethods = false)
@ConditionalOnProperty(name = "memox.test.database", havingValue = "local")
public class LocalPostgresConfiguration {

	@Bean
	DataSource dataSource(Environment environment) {
		return DataSourceBuilder.create()
				.url(environment.getRequiredProperty("memox.test.datasource.url"))
				.username(environment.getRequiredProperty("memox.test.datasource.username"))
				.password(environment.getProperty("memox.test.datasource.password", ""))
				.build();
	}
}
```

Guard the Testcontainers bean the same way so exactly one datasource is defined:

```java
@TestConfiguration(proxyBeanMethods = false)
@ConditionalOnProperty(name = "memox.test.database", havingValue = "testcontainers", matchIfMissing = true)
public class PostgresTestcontainersConfiguration { /* unchanged body */ }
```

`application-test.properties`:

```properties
spring.datasource.hikari.pool-name=memox-test-pool
spring.flyway.locations=classpath:db/migration
memox.test.database=${MEMOX_TEST_DATABASE:testcontainers}
memox.test.datasource.url=${MEMOX_TEST_DB_URL:jdbc:postgresql://localhost:5432/memox_test}
memox.test.datasource.username=${MEMOX_TEST_DB_USERNAME:giapnt}
memox.test.datasource.password=${MEMOX_TEST_DB_PASSWORD:}
```

- [ ] **Step 4: Reset every table, not just `decks`**

`PostgresIntegrationTest.java`:

```java
@ActiveProfiles("test")
@SpringBootTest
@Import({ PostgresTestcontainersConfiguration.class, LocalPostgresConfiguration.class })
public abstract class PostgresIntegrationTest {

	private static final String RESET_TABLES = String.join(", ",
			"study_queue_items", "study_answers", "study_sessions",
			"card_tags", "tags", "card_study_states", "cards", "decks", "delete_batches");

	@Autowired
	protected JdbcTemplate jdbcTemplate;

	@BeforeEach
	void clearMemoxData() {
		resetMemoxData();
	}

	protected void resetMemoxData() {
		jdbcTemplate.execute("TRUNCATE TABLE " + RESET_TABLES + " CASCADE");
		jdbcTemplate.update("UPDATE app_settings SET card_limit = 20, new_card_order = 'created', "
				+ "theme_mode = 'system', language = 'system', reminder_enabled = 0, "
				+ "reminder_minute_of_day = 1200, reminder_last_delivered_at = NULL, updated_at = ? WHERE id = 1",
				java.sql.Timestamp.from(java.time.Instant.EPOCH));
	}
}
```

`app_settings` is deliberately **not** in the truncate list: `V2` seeds its only row, and truncating it would delete the singleton that `V4`'s check constraint assumes.

- [ ] **Step 5: Create the local test database and run the suite**

```bash
psql -U giapnt -h localhost -c "CREATE DATABASE memox_test"
```

```bash
cd memox-api && MEMOX_TEST_DATABASE=local MEMOX_TEST_DB_PASSWORD=<local password> ./mvnw.cmd test
```

Expected: **32 tests, 0 failures, 0 errors.** Flyway creates `V1`…`V4` in `memox_test` on first run. If any pre-existing test fails here it is a real regression from the Docker→local switch and must be fixed before Task 1, not carried.

- [ ] **Step 6: Add `MemoxFixtures` with the signatures above**

Implement every method listed in **Interfaces** against `JdbcTemplate`. Two details that are easy to get wrong and that later tasks depend on:

```java
void insertSubDeckAt(String id, String name, String parentId, String rootId, int siblingPosition) {
    jdbcTemplate.update("""
            INSERT INTO decks (id, name, parent_deck_id, sibling_scope_id, sibling_position,
                               root_deck_id, content_type, created_at, updated_at)
            VALUES (?, ?, ?, ?, ?, ?, 'unset', ?, ?)""",
            id, name, parentId, parentId, siblingPosition, rootId, EPOCH, EPOCH);
}

void softDelete(String itemType, String itemId) {
    final var batchId = UUID.randomUUID().toString();
    jdbcTemplate.update("INSERT INTO delete_batches (id, item_type, root_item_id, deleted_at) VALUES (?, ?, ?, ?)",
            batchId, itemType, itemId, EPOCH);
    final var table = "deck".equals(itemType) ? "decks" : "cards";
    jdbcTemplate.update("UPDATE " + table + " SET delete_batch_id = ? WHERE id = ?", batchId, itemId);
}
```

`sibling_scope_id` must be set on every inserted sub-deck — it is `NOT NULL` with an all-zero default, so a fixture that omits it silently files every sub-deck into the **root** scope and collides with `uq_decks_sibling_scope_position` on the second insert. Roots use `DeckPositionScope.ROOT_DECKS`.

Verify with a fixture self-test that inserts two sub-decks under different parents at position `0` and asserts both exist — that is the assertion that fails if `sibling_scope_id` was forgotten.

- [x] **Step 7: Document the two ways to run the suite** — done, in `memox-api/README.md`.

This step originally said to write it into `memox-api/HELP.md`. That file is **gitignored** (it is Spring Initializr's generated stub), so following the step literally produces a `git add` that silently does nothing and documentation nobody else ever receives. The content lives in `README.md`'s "Running the tests" section instead: CI and any machine with Docker uses the default (`memox.test.database=testcontainers`); a machine without Docker exports `MEMOX_TEST_DATABASE=local` and the three `MEMOX_TEST_DB_*` variables against a database that is **never** the developer's `memox` database.

- [x] **Step 8: Commit** — landed as PR #512 and the Phase 2 prep commit.

---

## Task 1: The translation kit — boolean handler, `IN`-guard and the parity test

> **PARTLY DONE.** The Phase 2 prep commit landed the boolean handler and moved the two
> architecture rules this plan had scheduled for Task 15 forward to here, where they can still
> change what gets written. What each item's state is:
>
> | Item | State |
> |---|---|
> | `BooleanSmallIntTypeHandler` + `mybatis.type-handlers-package` | **done**, with one change from the code drafted below — see the note under it |
> | `sqlLivesOnlyInMapperXml` | **done and live**, moved forward from Task 15. It is `noMethods`, not `noClasses`: MyBatis puts `@Select` on the method, so the drafted class-level check could never fire |
> | `featuresDoNotReachEachOthersInternals` | **done and live**, moved forward from Task 15, renamed, and widened by one allowance the draft could not have anticipated — see Task 15 |
> | `IdCollections.requireNonEmpty` | **deliberately not built yet.** It has no caller until the first `IN`-list statement, and a guard with no call site guards nothing; Wave 3 had just removed `readSchemaVersion` for exactly that. Build it in the task that first needs it — Task 9 — together with the cap below |
> | A batch-size cap for `IN`-list operations | **decided here, because the plan never specified one:** **500 ids** per request for bulk move, bulk flag, bulk delete and restore. Reject a larger list with `VALIDATION_FAILED` rather than truncating it, so a client that exceeds it learns rather than silently loses rows. 500 keeps a single statement's parameter list well under PostgreSQL's 65 535 bind limit even at several parameters per id, and is far above any list a person assembles by hand in the UI |
>
> **One change from the drafted handler, and it matters.** The draft says
> `@MappedJdbcTypes(value = JdbcType.SMALLINT, includeNullJdbcType = true)`. Do not use
> `includeNullJdbcType`: it also makes this the handler for every boolean with no JDBC type
> stated, including `activeDeckExists`, whose `SELECT EXISTS (...)` returns a real PostgreSQL
> BOOLEAN that would then be read with `getShort`. It is bound to SMALLINT only, and statements
> that want it say so — `typeHandler=` on the result-map argument, or `jdbcType=SMALLINT` on the
> bind. `TypeHandlerRegistrationTest` asserts both halves of that.
>
> `@MappedTypes` names **both** `Boolean.class` and `boolean.class`. MyBatis keys its registry on
> the exact class, and the primitive and the wrapper are different keys — the same distinction that
> made `javaType="int"` mean `Integer` and turned every deck creation into an HTTP 500.

**Files:**
- Create: `memox-api/src/main/java/com/memox/common/mybatis/BooleanSmallIntTypeHandler.java`
- Create: `memox-api/src/main/java/com/memox/common/persistence/IdCollections.java`
- Create: `memox-api/src/test/java/com/memox/common/mybatis/BooleanSmallIntTypeHandlerTest.java`
- Create: `memox-api/src/test/java/com/memox/common/persistence/IdCollectionsTest.java`
- Modify: `memox-api/src/main/resources/application.properties`

**Interfaces:**
- Produces: `BooleanSmallIntTypeHandler` — registered globally via `mybatis.type-handlers-package`, maps `java.lang.Boolean` ↔ `SMALLINT` 0/1. Used by every `is_flagged`, `used_hint`, `is_revealed` and `reminder_enabled` binding.
- Produces: `IdCollections.requireNonEmpty(Collection<String> ids, String name)` → `List<String>`; throws `IllegalArgumentException` when empty. Every service that is about to call an `IN`-collection statement calls it first.

- [ ] **Step 1: Write the failing tests**

```java
class BooleanSmallIntTypeHandlerTest {

	private final BooleanSmallIntTypeHandler handler = new BooleanSmallIntTypeHandler();

	@Test
	void writesTrueAsOne() throws SQLException {
		final var statement = mock(PreparedStatement.class);
		handler.setNonNullParameter(statement, 1, Boolean.TRUE, JdbcType.SMALLINT);
		verify(statement).setShort(1, (short) 1);
	}

	@Test
	void readsZeroAsFalse() throws SQLException {
		final var resultSet = mock(ResultSet.class);
		when(resultSet.getShort("is_flagged")).thenReturn((short) 0);
		when(resultSet.wasNull()).thenReturn(false);
		assertThat(handler.getNullableResult(resultSet, "is_flagged")).isFalse();
	}
}
```

```java
class IdCollectionsTest {

	@Test
	void rejectsAnEmptyCollectionBeforeItReachesSql() {
		assertThatThrownBy(() -> IdCollections.requireNonEmpty(List.of(), "cardIds"))
				.isInstanceOf(IllegalArgumentException.class)
				.hasMessageContaining("cardIds");
	}

	@Test
	void returnsAnImmutableCopyInOrder() {
		final var ids = IdCollections.requireNonEmpty(List.of("a", "b"), "cardIds");
		assertThat(ids).containsExactly("a", "b");
		assertThatThrownBy(() -> ids.add("c")).isInstanceOf(UnsupportedOperationException.class);
	}
}
```

- [ ] **Step 2: Run them and verify they fail**

```bash
cd memox-api && ./mvnw.cmd -Dtest='BooleanSmallIntTypeHandlerTest,IdCollectionsTest' test
```

Expected: FAIL — both classes are missing.

- [ ] **Step 3: Implement both**

```java
package com.memox.common.mybatis;

@MappedTypes(Boolean.class)
@MappedJdbcTypes(value = JdbcType.SMALLINT, includeNullJdbcType = true)
public class BooleanSmallIntTypeHandler extends BaseTypeHandler<Boolean> {

	private static final short TRUE_VALUE = 1;
	private static final short FALSE_VALUE = 0;

	@Override
	public void setNonNullParameter(PreparedStatement statement, int index, Boolean parameter, JdbcType jdbcType)
			throws SQLException {
		statement.setShort(index, Boolean.TRUE.equals(parameter) ? TRUE_VALUE : FALSE_VALUE);
	}

	@Override
	public Boolean getNullableResult(ResultSet resultSet, String columnName) throws SQLException {
		final var value = resultSet.getShort(columnName);
		return resultSet.wasNull() ? null : value != FALSE_VALUE;
	}

	@Override
	public Boolean getNullableResult(ResultSet resultSet, int columnIndex) throws SQLException {
		final var value = resultSet.getShort(columnIndex);
		return resultSet.wasNull() ? null : value != FALSE_VALUE;
	}

	@Override
	public Boolean getNullableResult(CallableStatement statement, int columnIndex) throws SQLException {
		final var value = statement.getShort(columnIndex);
		return statement.wasNull() ? null : value != FALSE_VALUE;
	}
}
```

```java
package com.memox.common.persistence;

@UtilityClass
public class IdCollections {

	public List<String> requireNonEmpty(Collection<String> ids, String parameterName) {
		Objects.requireNonNull(ids, parameterName + " must not be null");
		if (ids.isEmpty()) {
			throw new IllegalArgumentException(parameterName + " must not be empty");
		}
		return List.copyOf(ids);
	}
}
```

Register the handler in `application.properties`:

```properties
mybatis.type-handlers-package=com.memox.common.mybatis
```

- [ ] **Step 4: Run both tests and verify they pass**

```bash
cd memox-api && ./mvnw.cmd -Dtest='BooleanSmallIntTypeHandlerTest,IdCollectionsTest' test
```

Expected: PASS, 4 tests.

- [ ] **Step 5: Prove the handler works against real PostgreSQL**

Add to `memox-api/src/test/java/com/memox/card/persistence/CardMapperTest.java` (new file, extends `PostgresIntegrationTest`) a test that inserts a card, calls a new `setCardsFlagByIds`-shaped update binding `true`, and reads `is_flagged` back as `1`. This is the test that would have caught `column "is_flagged" is of type smallint but expression is of type boolean` — a mock cannot.

- [ ] **Step 6: Commit**

```bash
git add memox-api/src/main/java/com/memox/common memox-api/src/test/java/com/memox/common memox-api/src/main/resources/application.properties memox-api/src/test/java/com/memox/card/persistence
git commit -m "feat(api): add the smallint boolean handler and the IN-collection guard"
```

---

## Task 2: Deck tree reads — root summaries, whole tree, one subtree

Ports `rootDeckSummaries`, `allDecks`, `decksInTree`. `rootDeckSummaries` is the single largest read in the app and the one the Library screen depends on; it carries seven aggregate counts plus `nextDueAt`.

**Files:**
- Create: `memox-api/src/main/java/com/memox/deck/entity/DeckSummary.java`
- Modify: `memox-api/src/main/java/com/memox/deck/persistence/DeckMapper.java`
- Modify: `memox-api/src/main/resources/mybatis/deck_mapper.xml`
- Create: `memox-api/src/main/java/com/memox/deck/service/DeckTreeService.java`
- Create: `memox-api/src/main/java/com/memox/deck/dto/response/DeckSummaryResponse.java`
- Modify: `memox-api/src/main/java/com/memox/deck/controller/DeckController.java`
- Create: `memox-api/src/test/java/com/memox/deck/DeckSummaryTest.java`

**Interfaces:**
- Consumes: `PageQuery`, `PageHelper`, `Clock` (Task 0's harness).
- Produces: `DeckSummary(String id, String name, String rootDeckId, DeckContentType contentType, SchedulerType schedulerType, int siblingPosition, long totalCardCount, long newCardCount, long dueCardCount, long overdueCardCount, Instant oldestDueAt, long learnedCardCount, long subDeckCount, Instant nextDueAt, Instant createdAt, Instant updatedAt)`.
- Produces: `DeckTreeService.listRootSummaries(PageQuery, Instant now, Instant startOfToday)` → `PagingResponse<DeckSummary>`; `DeckTreeService.listTree(String rootDeckId)` → `List<Deck>`; `DeckTreeService.listAllActive()` → `List<Deck>`.

- [ ] **Step 1: Write the failing test**

```java
class DeckSummaryTest extends PostgresIntegrationTest {

	@Autowired DeckTreeService deckTreeService;

	@Test
	void countsCardsThroughTheRootDeckAndNotThroughTheImmediateParent() {
		// root -> level2 -> level3, one card in level3 only.
		insertRootDeck("root", "Korean");
		insertSubDeck("level2", "Unit 1", "root", "root");
		insertSubDeck("level3", "Lesson 1", "level2", "root");
		insertCardWithState("card-1", "level3", /* learnedAt */ null, /* dueAt */ null);

		final var page = deckTreeService.listRootSummaries(PageQuery.builder().build(),
				Instant.parse("2026-09-09T00:00:00Z"), Instant.parse("2026-09-09T00:00:00Z"));

		assertThat(page.getItems()).singleElement().satisfies(summary -> {
			assertThat(summary.id()).isEqualTo("root");
			assertThat(summary.totalCardCount()).isEqualTo(1);   // reached via root_deck_id, three levels down
			assertThat(summary.newCardCount()).isEqualTo(1);     // learned_at IS NULL
			assertThat(summary.dueCardCount()).isZero();
			assertThat(summary.subDeckCount()).isEqualTo(1);     // direct children only
		});
	}

	@Test
	void excludesSoftDeletedCardsFromEveryCount() {
		insertRootDeck("root", "Korean");
		insertSubDeck("level2", "Unit 1", "root", "root");
		insertCardWithState("kept", "level2", null, null);
		insertCardWithState("trashed", "level2", null, null);
		softDelete("card", "trashed");

		final var page = deckTreeService.listRootSummaries(PageQuery.builder().build(),
				Instant.parse("2026-09-09T00:00:00Z"), Instant.parse("2026-09-09T00:00:00Z"));

		assertThat(page.getItems()).singleElement()
				.extracting(DeckSummary::totalCardCount, DeckSummary::newCardCount)
				.containsExactly(1L, 1L);   // BR-257
	}
}
```

- [ ] **Step 2: Run and verify it fails**

```bash
cd memox-api && ./mvnw.cmd -Dtest=DeckSummaryTest test
```

Expected: FAIL — `DeckTreeService` does not exist.

- [ ] **Step 3: Add the statement**

`deck_mapper.xml`, applying translation rows 11 and 12. The five `LEFT JOIN` sub-aggregates and the `nextDueAt` scalar sub-select are copied structurally from `rootDeckSummaries`; only the parameter syntax changes.

```xml
<resultMap id="deckSummary" type="com.memox.deck.entity.DeckSummary">
  <constructor>
    <idArg column="id" javaType="java.lang.String"/>
    <arg column="name" javaType="java.lang.String"/>
    <arg column="root_deck_id" javaType="java.lang.String"/>
    <arg column="content_type" javaType="com.memox.deck.enums.DeckContentType"
         typeHandler="com.memox.deck.persistence.DeckContentTypeTypeHandler"/>
    <arg column="scheduler_type" javaType="com.memox.deck.enums.SchedulerType"
         typeHandler="com.memox.deck.persistence.SchedulerTypeTypeHandler"/>
    <arg column="sibling_position" javaType="_int"/>
    <arg column="total_card_count" javaType="_long"/>
    <arg column="new_card_count" javaType="_long"/>
    <arg column="due_card_count" javaType="_long"/>
    <arg column="overdue_card_count" javaType="_long"/>
    <arg column="oldest_due_at" javaType="java.time.Instant"/>
    <arg column="learned_card_count" javaType="_long"/>
    <arg column="sub_deck_count" javaType="_long"/>
    <arg column="next_due_at" javaType="java.time.Instant"/>
    <arg column="created_at" javaType="java.time.Instant"/>
    <arg column="updated_at" javaType="java.time.Instant"/>
  </constructor>
</resultMap>

<select id="findRootDeckSummaries" resultMap="deckSummary">
  SELECT d.id, d.name, d.root_deck_id, d.content_type, d.scheduler_type, d.sibling_position,
         COALESCE(total.card_count, 0)     AS total_card_count,
         COALESCE(new.new_count, 0)        AS new_card_count,
         COALESCE(due.due_count, 0)        AS due_card_count,
         COALESCE(due.overdue_count, 0)    AS overdue_card_count,
         due.oldest_due_at                 AS oldest_due_at,
         COALESCE(learned.learned_count, 0) AS learned_card_count,
         COALESCE(sub.sub_count, 0)        AS sub_deck_count,
         (SELECT MIN(nx.due_at)
            FROM card_study_states nx
            INNER JOIN cards nc ON nc.id = nx.card_id
            INNER JOIN decks nd ON nd.id = nc.deck_id
           WHERE nx.due_at &gt; #{now}
             AND nd.root_deck_id = d.id
             AND nc.delete_batch_id IS NULL
             AND nd.delete_batch_id IS NULL) AS next_due_at,
         d.created_at, d.updated_at
    FROM decks d
    LEFT JOIN (SELECT cd.root_deck_id AS root_deck_id, COUNT(*) AS card_count
                 FROM cards c
                 INNER JOIN decks cd ON cd.id = c.deck_id
                WHERE c.delete_batch_id IS NULL AND cd.delete_batch_id IS NULL
                GROUP BY cd.root_deck_id) total ON total.root_deck_id = d.id
    LEFT JOIN (SELECT cd.root_deck_id AS root_deck_id, COUNT(*) AS new_count
                 FROM cards c
                 INNER JOIN decks cd ON cd.id = c.deck_id
                 INNER JOIN card_study_states s ON s.card_id = c.id
                WHERE s.learned_at IS NULL
                  AND c.delete_batch_id IS NULL AND cd.delete_batch_id IS NULL
                GROUP BY cd.root_deck_id) new ON new.root_deck_id = d.id
    LEFT JOIN (SELECT cd.root_deck_id AS root_deck_id, COUNT(*) AS due_count,
                      SUM(CASE WHEN s.due_at &lt; #{startOfToday} THEN 1 ELSE 0 END) AS overdue_count,
                      MIN(s.due_at) AS oldest_due_at
                 FROM cards c
                 INNER JOIN decks cd ON cd.id = c.deck_id
                 INNER JOIN card_study_states s ON s.card_id = c.id
                WHERE s.learned_at IS NOT NULL AND s.due_at &lt;= #{now}
                  AND c.delete_batch_id IS NULL AND cd.delete_batch_id IS NULL
                GROUP BY cd.root_deck_id) due ON due.root_deck_id = d.id
    LEFT JOIN (SELECT cd.root_deck_id AS root_deck_id, COUNT(*) AS learned_count
                 FROM cards c
                 INNER JOIN decks cd ON cd.id = c.deck_id
                 INNER JOIN card_study_states s ON s.card_id = c.id
                WHERE ((s.scheduler_type = 'eight_box' AND s.current_box = 8)
                    OR (s.scheduler_type = 'sm2' AND s.interval_days &gt;= 128))
                  AND c.delete_batch_id IS NULL AND cd.delete_batch_id IS NULL
                GROUP BY cd.root_deck_id) learned ON learned.root_deck_id = d.id
    LEFT JOIN (SELECT parent_deck_id AS parent_id, COUNT(*) AS sub_count
                 FROM decks
                WHERE parent_deck_id IS NOT NULL AND delete_batch_id IS NULL
                GROUP BY parent_deck_id) sub ON sub.parent_id = d.id
   WHERE d.parent_deck_id IS NULL AND d.delete_batch_id IS NULL
   <include refid="orderBySlice"/>
   LIMIT #{slice.limit} OFFSET #{slice.offset}
</select>
```

**CORRECTED — this paragraph used to call the missing correlation a bug, and it is not one.** `nextDueAt` takes `MIN(due_at)` across the whole database on purpose: it is the earliest instant at which any `dueCardCount` on the page would change, and the list screen schedules its next re-measure from it. It is a screen-level timer delivered on every row, not a per-deck fact, and `deck.drift` says so twice — once above the statement ("one scalar subquery, evaluated once per statement") and once beside `childDeckLevel` ("the whole database is its horizon and the global MIN in `rootDeckSummaries` is correct there"). Correlating it on `root_deck_id` changes the meaning — the screen wakes at the first tree's boundary and is late for the others — and turns one scalar into a per-row correlated sub-query. **Do not add the correlation.** It was added and merged in PR #516 on the strength of this paragraph, and reverted immediately afterwards.

**The real divergence is smaller.** `nextDueAt` also excludes cards whose *deck* is in Trash. Drift joins `cards` alone, so it drops a trashed card but keeps a card sitting in a trashed deck — while every count beside it checks `cd.delete_batch_id`. Drift's own reason covers both ("a state whose card is in Trash must not set the moment this screen wakes up at", BR-257). Record *that* in the parity document (Task 15) with a WBS entry against the Flutter side rather than editing `lib/`.

`findAllActiveDecks` and `findDecksInTree` are direct copies of `allDecks` and `decksInTree` with the existing `deck` result map and the column list already used by `findRootDecks`.

- [ ] **Step 4: Add the service, DTO and endpoints**

`DeckTreeService.listRootSummaries` is `@Transactional(readOnly = true)` and returns `PageHelper.create(pageQuery, mapper.findRootDeckSummaries(...), mapper.countRootDecks())`. `now` and `startOfToday` come from the controller, which derives them from `Clock` and the request's `X-Utc-Offset-Minutes` header (default `0`) — the server never guesses a local midnight (BR-105).

`GET /api/v1/decks/summaries` returns `PagingResponse<DeckSummaryResponse>`; `GET /api/v1/decks/{rootDeckId}/tree` returns `List<DeckResponse>`.

- [ ] **Step 5: Run the tests and verify they pass**

```bash
cd memox-api && ./mvnw.cmd -Dtest=DeckSummaryTest test
```

Expected: PASS, 2 tests.

- [ ] **Step 6: Commit**

```bash
git add memox-api/src/main/java/com/memox/deck memox-api/src/main/resources/mybatis/deck_mapper.xml memox-api/src/test/java/com/memox/deck
git commit -m "feat(deck): port root deck summaries and tree reads to MyBatis"
```

---

## Task 3: The deck level view — `childDeckLevel` and `deckContextById`

The hardest read in the module: one statement returning the parent, every child, each child's whole-subtree counts via a recursive `branch` CTE, the inherited scheduler, and the parent's ancestry path as JSON. `deckContextById` is the same ancestry shape for a card's deck, so both land here and share one JSON contract.

**Files:**
- Create: `memox-api/src/main/java/com/memox/deck/entity/DeckAncestor.java`
- Create: `memox-api/src/main/java/com/memox/deck/entity/DeckLevelChild.java`
- Create: `memox-api/src/main/java/com/memox/deck/entity/DeckLevel.java`
- Create: `memox-api/src/main/java/com/memox/deck/entity/DeckContext.java`
- Create: `memox-api/src/main/java/com/memox/deck/service/DeckLimits.java` *(a constants holder; `entity/` is for what the mapper reads back, and the depth ceiling is a rule the service enforces)*
- Create: `memox-api/src/main/java/com/memox/deck/persistence/AncestryJsonTypeHandler.java`
- Modify: `memox-api/src/main/resources/mybatis/deck_mapper.xml`
- Modify: `memox-api/src/main/java/com/memox/deck/service/DeckTreeService.java`
- Create: `memox-api/src/test/java/com/memox/deck/DeckLevelTest.java`

**Interfaces:**
- Consumes: `DeckMapper`, translation rows 2 and 10.
- Produces: `DeckAncestor(String id, String name, int distance)`; `DeckLevelChild(Deck child, SchedulerType inheritedSchedulerType, long totalCardCount, long newCardCount, long dueCardCount, long overdueCardCount, Instant oldestDueAt, long learnedCardCount, long subDeckCount)`; `DeckContext(String deckId, String deckName, DeckContentType contentType, List<DeckAncestor> ancestry)`.
- Produces: `DeckTreeService.readLevel(String deckId, Instant now, Instant startOfToday)` → `DeckLevel(DeckContext parent, List<DeckLevelChild> children, Instant nextDueAt)`; `DeckTreeService.readContext(String deckId)` → `DeckContext`. Both return `null` for a deck that is missing or in Trash.

**CORRECTED — three interface declarations here did not match the statement below them.**

1. `DeckLevel` held a full `Deck parent`, but the SELECT lists three parent columns. The parent is a `DeckContext` now — which is also exactly what `deckContextById` produces, so the two statements this task ports share one shape rather than merely sharing a JSON contract.
2. `DeckLevelChild` held `nextDueAt`. That instant is scoped to the level, not to a child, so it moved to `DeckLevel`. Per-child it would publish a number the statement does not measure.
3. `DeckContext` had no `deckId`, leaving the response unable to say which deck it describes.

**The result map is flat, not nested.** MyBatis can nest a result map inside a constructor argument; this module has already paid once for a mapping mistake that produced no error and no value (`javaType="int"` silently meaning `Integer`), so the row is scalars (`DeckLevelRow`) and the folding is ordinary Java in the service, where it is tested.

- [ ] **Step 1: Write the failing test**

```java
class DeckLevelTest extends PostgresIntegrationTest {

	@Autowired DeckTreeService deckTreeService;

	@Test
	void returnsAnEmptyAncestryListForAFirstLevelParent() {
		insertRootDeck("root", "Korean");
		insertSubDeck("level2", "Unit 1", "root", "root");

		final var level = deckTreeService.readLevel("root", NOW, START_OF_TODAY);

		assertThat(level.ancestry()).isEmpty();   // translation row 2: [] and not null
		assertThat(level.children()).singleElement()
				.extracting(child -> child.child().id()).isEqualTo("level2");
	}

	@Test
	void countsACardThatSitsTwoLevelsBelowTheChild() {
		insertRootDeck("root", "Korean");
		insertSubDeck("a", "Unit 1", "root", "root");
		insertSubDeck("b", "Lesson 1", "a", "root");
		insertSubDeck("c", "Set 1", "b", "root");
		insertCardWithState("card-1", "c", null, null);

		final var level = deckTreeService.readLevel("root", NOW, START_OF_TODAY);

		assertThat(level.children()).singleElement()
				.extracting(DeckLevelChild::totalCardCount).isEqualTo(1L);   // branch CTE, not a direct count
	}

	@Test
	void reportsTheAncestryOfADeepParentNearestFirst() {
		insertRootDeck("root", "Korean");
		insertSubDeck("a", "Unit 1", "root", "root");
		insertSubDeck("b", "Lesson 1", "a", "root");

		final var level = deckTreeService.readLevel("b", NOW, START_OF_TODAY);

		assertThat(level.ancestry())
				.extracting(DeckAncestor::id, DeckAncestor::distance)
				.containsExactly(tuple("a", 1), tuple("root", 2));
	}
}
```

- [ ] **Step 2: Run and verify it fails**

```bash
cd memox-api && ./mvnw.cmd -Dtest=DeckLevelTest test
```

Expected: FAIL — `readLevel` does not exist.

- [ ] **Step 3: Port the statement**

The recursive header is unchanged from Drift (translation row 10). The two changes are `json_group_array(json_object(…))` → `COALESCE(json_agg(json_build_object(…) ORDER BY a.distance), '[]'::json)` (row 2, plus the explicit order the client's "nearest first" display needs), and `:param` → `#{param}`.

```xml
<select id="findChildDeckLevel" resultMap="deckLevelChild">
  WITH RECURSIVE branch (branch_id, deck_id) AS (
      SELECT id, id FROM decks
       WHERE parent_deck_id = #{parentId} AND delete_batch_id IS NULL
      UNION
      SELECT b.branch_id, d.id
        FROM decks d
        INNER JOIN branch b ON d.parent_deck_id = b.deck_id
       WHERE d.delete_batch_id IS NULL
  ),
  ancestry (deck_id, distance) AS (
      SELECT parent_deck_id, 1 FROM decks
       WHERE id = #{parentId} AND parent_deck_id IS NOT NULL
      UNION
      SELECT d.parent_deck_id, a.distance + 1
        FROM decks d
        INNER JOIN ancestry a ON d.id = a.deck_id
       WHERE d.parent_deck_id IS NOT NULL AND a.distance &lt; #{maxWalk}
  )
  SELECT parent.id AS parent_id, parent.name AS parent_name,
         parent.content_type AS parent_content_type,
         child.id, child.name, child.parent_deck_id, child.root_deck_id,
         child.content_type, child.sibling_position, child.created_at, child.updated_at,
         root.scheduler_type AS inherited_scheduler_type,
         COALESCE(total.card_count, 0)      AS total_card_count,
         COALESCE(new.new_count, 0)         AS new_card_count,
         COALESCE(due.due_count, 0)         AS due_card_count,
         COALESCE(due.overdue_count, 0)     AS overdue_card_count,
         due.oldest_due_at                  AS oldest_due_at,
         COALESCE(learned.learned_count, 0) AS learned_card_count,
         COALESCE(sub.sub_count, 0)         AS sub_deck_count,
         (SELECT MIN(nx.due_at)
            FROM branch fb
            INNER JOIN cards fc ON fc.deck_id = fb.deck_id
            INNER JOIN card_study_states nx ON nx.card_id = fc.id
           WHERE nx.due_at &gt; #{now} AND fb.branch_id = child.id
             AND fc.delete_batch_id IS NULL) AS next_due_at,
         (SELECT COALESCE(json_agg(json_build_object('id', a.deck_id, 'name', d.name,
                                                     'distance', a.distance)
                                   ORDER BY a.distance), '[]'::json)
            FROM ancestry a
            INNER JOIN decks d ON d.id = a.deck_id) AS ancestry_json
    FROM decks AS parent
    LEFT JOIN decks AS child ON child.parent_deck_id = parent.id AND child.delete_batch_id IS NULL
    LEFT JOIN decks AS root  ON root.id = child.root_deck_id
    LEFT JOIN (SELECT b.branch_id AS branch_id, COUNT(*) AS card_count
                 FROM branch b
                 INNER JOIN cards c ON c.deck_id = b.deck_id
                WHERE c.delete_batch_id IS NULL
                GROUP BY b.branch_id) total ON total.branch_id = child.id
    LEFT JOIN (SELECT b.branch_id AS branch_id, COUNT(*) AS new_count
                 FROM branch b
                 INNER JOIN cards c ON c.deck_id = b.deck_id
                 INNER JOIN card_study_states s ON s.card_id = c.id
                WHERE s.learned_at IS NULL AND c.delete_batch_id IS NULL
                GROUP BY b.branch_id) new ON new.branch_id = child.id
    LEFT JOIN (SELECT b.branch_id AS branch_id, COUNT(*) AS due_count,
                      SUM(CASE WHEN s.due_at &lt; #{startOfToday} THEN 1 ELSE 0 END) AS overdue_count,
                      MIN(s.due_at) AS oldest_due_at
                 FROM branch b
                 INNER JOIN cards c ON c.deck_id = b.deck_id
                 INNER JOIN card_study_states s ON s.card_id = c.id
                WHERE s.learned_at IS NOT NULL AND s.due_at &lt;= #{now}
                  AND c.delete_batch_id IS NULL
                GROUP BY b.branch_id) due ON due.branch_id = child.id
    LEFT JOIN (SELECT b.branch_id AS branch_id, COUNT(*) AS learned_count
                 FROM branch b
                 INNER JOIN cards c ON c.deck_id = b.deck_id
                 INNER JOIN card_study_states s ON s.card_id = c.id
                WHERE ((s.scheduler_type = 'eight_box' AND s.current_box = 8)
                    OR (s.scheduler_type = 'sm2' AND s.interval_days &gt;= 128))
                  AND c.delete_batch_id IS NULL
                GROUP BY b.branch_id) learned ON learned.branch_id = child.id
    LEFT JOIN (SELECT parent_deck_id AS parent_id, COUNT(*) AS sub_count
                 FROM decks
                WHERE parent_deck_id IS NOT NULL AND delete_batch_id IS NULL
                GROUP BY parent_deck_id) sub ON sub.parent_id = child.id
   WHERE parent.id = #{parentId} AND parent.delete_batch_id IS NULL
   ORDER BY child.sibling_position ASC, child.id ASC
</select>
```

The four `branch`-keyed aggregates are what make a child's counts cover its **whole subtree** rather than its direct cards, and `sub` is deliberately *not* branch-keyed: `subDeckCount` is a direct-child count in Drift and stays one here.

`findChildDeckLevel` returns one row per child (or a single row with a null child when the parent is empty), so `DeckTreeService.readLevel` filters the null-child row out before building `DeckLevel`.

**CORRECTED — the same mistake as Task 2, for the same reason.** Reading the whole `branch` CTE is deliberate: this scalar is the level screen's re-measure timer, and `deck.drift` states its scope explicitly — "scoped to this level's subtrees, unlike the root's … the earliest instant at which one of *these* counts changes". Restricting it to `child.id` would turn a screen-level timer into a per-child value and a once-per-statement scalar into a per-row one. **Do not add `AND fb.branch_id = child.id`.** Port the sub-select unchanged.

`AncestryJsonTypeHandler` extends `BaseTypeHandler<List<DeckAncestor>>` and reads the column with a shared `ObjectMapper`; it returns `List.of()` for `null` so a future non-`COALESCE`d caller still cannot NPE.

- [ ] **Step 4: Add the endpoint**

`GET /api/v1/decks/{deckId}/level` → `DeckLevelResponse`. `maxWalk` is bound from the existing `MAX_TREE_DEPTH = 10`, promoted to `com.memox.deck.service.DeckLimits.MAX_TREE_DEPTH` so the service, the mapper call and the depth probe in Task 4 read one constant.

- [ ] **Step 5: Run the tests and verify they pass**

```bash
cd memox-api && ./mvnw.cmd -Dtest=DeckLevelTest test
```

Expected: PASS, 3 tests.

- [ ] **Step 6: Commit**

```bash
git add memox-api/src/main/java/com/memox/deck memox-api/src/main/resources/mybatis/deck_mapper.xml memox-api/src/test/java/com/memox/deck
git commit -m "feat(deck): port the deck level view and ancestry path"
```

---

## Task 4: Structural probes — depth, height, counts, subtree ids

Replaces `DeckService.depthOf`, which today walks the tree with up to ten separate `SELECT`s inside the write transaction. Drift answers the same question in one recursive statement, and so should the server.

**Files:**
- Create: `memox-api/src/main/java/com/memox/deck/entity/DeckDepth.java`
- ~~Modify: `memox-api/src/main/java/com/memox/deck/service/DeckLimits.java`~~ *(both constants landed with Task 3, which needed `MAX_WALK` for its ancestry walks)*
- Modify: `memox-api/src/main/java/com/memox/deck/persistence/DeckMapper.java`
- Modify: `memox-api/src/main/resources/mybatis/deck_mapper.xml`
- Create: `memox-api/src/main/java/com/memox/deck/service/DeckStructureService.java`
- Modify: `memox-api/src/main/java/com/memox/deck/service/DeckService.java`
- Create: `memox-api/src/test/java/com/memox/deck/DeckStructureTest.java`

**Interfaces:**
- Produces: `DeckDepth(int depth, boolean reachedRoot)`; `DeckLimits.MAX_TREE_DEPTH = 10`, `DeckLimits.MAX_WALK = 11`.
- Produces: `DeckStructureService.depthOf(String deckId)` → `int`; `.subtreeHeight(String deckId)` → `int`; `.subtreeDeckIds(String deckId)` → `List<String>`; `.directChildDeckCount(String)`, `.directCardCount(String)`, `.subtreeCardCount(String)` → `long`.
- `DeckService.createSubDeck` switches from `depthOf(Deck)` to `deckStructureService.depthOf(parent.id())`.

`MAX_WALK` is `MAX_TREE_DEPTH + 1` on purpose: the probe must be able to *observe* an eleventh level in order to reject it, so a walk capped at ten cannot tell "exactly at the limit" from "over it".

- [ ] **Step 1: Write the failing test**

```java
class DeckStructureTest extends PostgresIntegrationTest {

	@Autowired DeckStructureService deckStructureService;

	@Test
	void reportsRootDepthAsOne() {
		insertRootDeck("root", "Korean");
		assertThat(deckStructureService.depthOf("root")).isEqualTo(1);   // BR-55: root is level 1
	}

	@Test
	void reportsTheTenthLevelAsTen() {
		insertChain(10);   // root + 9 sub-decks, ids "d1".."d10"
		assertThat(deckStructureService.depthOf("d10")).isEqualTo(10);
	}

	@Test
	void reportsSubtreeHeightFromTheGivenNode() {
		insertChain(4);
		assertThat(deckStructureService.subtreeHeight("d2")).isEqualTo(3);   // d2,d3,d4
	}

	@Test
	void countsOnlyActiveCardsInASubtree() {
		insertRootDeck("root", "Korean");
		insertSubDeck("a", "Unit 1", "root", "root");
		insertSubDeck("b", "Lesson 1", "a", "root");
		insertCardWithState("kept", "b", null, null);
		insertCardWithState("trashed", "b", null, null);
		softDelete("card", "trashed");

		assertThat(deckStructureService.subtreeCardCount("a")).isEqualTo(1);   // BR-257
	}
}
```

- [ ] **Step 2: Run and verify it fails**

```bash
cd memox-api && ./mvnw.cmd -Dtest=DeckStructureTest test
```

Expected: FAIL — `DeckStructureService` does not exist.

- [ ] **Step 3: Port the five statements**

```xml
<select id="probeDeckDepth" resultType="com.memox.deck.entity.DeckDepth">
  WITH RECURSIVE ancestry (node_id, parent_id, depth) AS (
      SELECT id, parent_deck_id, 1 FROM decks
       WHERE id = #{deckId} AND delete_batch_id IS NULL
      UNION ALL
      SELECT d.id, d.parent_deck_id, a.depth + 1
        FROM decks d
        INNER JOIN ancestry a ON d.id = a.parent_id
       WHERE a.depth &lt; #{maxWalk} AND d.delete_batch_id IS NULL
  )
  SELECT depth AS depth, (parent_id IS NULL) AS reached_root
    FROM ancestry
   ORDER BY depth DESC
   LIMIT 1
</select>

<select id="probeSubtreeHeight" resultType="java.lang.Integer">
  WITH RECURSIVE walk (id, height) AS (
      SELECT id, 1 FROM decks WHERE id = #{deckId} AND delete_batch_id IS NULL
      UNION ALL
      SELECT d.id, w.height + 1
        FROM decks d
        INNER JOIN walk w ON d.parent_deck_id = w.id
       WHERE w.height &lt; #{maxWalk} AND d.delete_batch_id IS NULL
  )
  SELECT MAX(height) FROM walk
</select>

<select id="findSubtreeDeckIds" resultType="java.lang.String">
  WITH RECURSIVE subtree (id) AS (
      SELECT id FROM decks WHERE id = #{deckId} AND delete_batch_id IS NULL
      UNION
      SELECT d.id FROM decks d
        INNER JOIN subtree s ON d.parent_deck_id = s.id
       WHERE d.delete_batch_id IS NULL
  )
  SELECT id FROM subtree
</select>

<select id="countDirectChildDecks" resultType="long">
  SELECT COUNT(*) FROM decks WHERE parent_deck_id = #{deckId} AND delete_batch_id IS NULL
</select>

<select id="countDirectCards" resultType="long">
  SELECT COUNT(*) FROM cards WHERE deck_id = #{deckId} AND delete_batch_id IS NULL
</select>

<select id="countSubtreeCards" resultType="long">
  WITH RECURSIVE subtree (id) AS (
      SELECT id FROM decks WHERE id = #{deckId} AND delete_batch_id IS NULL
      UNION
      SELECT d.id FROM decks d
        INNER JOIN subtree s ON d.parent_deck_id = s.id
       WHERE d.delete_batch_id IS NULL
  )
  SELECT COUNT(*) FROM cards c
   WHERE c.deck_id IN (SELECT id FROM subtree) AND c.delete_batch_id IS NULL
</select>
```

`(parent_id IS NULL)` is a PostgreSQL `boolean` (translation row 7), so `DeckDepth.reachedRoot` is `boolean`, not `int`.

- [ ] **Step 4: Point `DeckService` at the probe**

Delete the `depthOf(Deck)` loop and its `requireActiveDeck` calls; call `deckStructureService.depthOf(parent.id())` instead. The existing `DeckControllerTest.rejectsCreatingAnEleventhDeckLevel` must still pass unchanged — that is the regression gate for this swap.

- [ ] **Step 5: Run the deck suite**

```bash
cd memox-api && ./mvnw.cmd -Dtest='DeckStructureTest,DeckControllerTest,DeckMapperTest' test
```

Expected: PASS. `rejectsCreatingAnEleventhDeckLevel` still green proves the replacement is behaviour-preserving.

- [ ] **Step 6: Commit**

```bash
git add memox-api/src/main/java/com/memox/deck memox-api/src/main/resources/mybatis/deck_mapper.xml memox-api/src/test/java/com/memox/deck
git commit -m "feat(deck): answer depth and subtree questions in one statement"
```

---

## Task 5: Deck reorder — and the migration it needs

**Blocker discovered while reading the schema.** `V3` added `uq_decks_sibling_scope_position UNIQUE (sibling_scope_id, sibling_position)` and `V4` added `ck_decks_sibling_position_non_negative CHECK (sibling_position >= 0)`. A reorder that shifts a run of siblings collides on the unique index part-way through the run, and the usual escape — park the moved row at a negative position — is blocked by the check. The constraint is not `DEFERRABLE`, and PostgreSQL's `ALTER TABLE … ALTER CONSTRAINT` only re-arms foreign keys, so it must be dropped and re-added.

> **The migration is already applied.** The Phase 2 prep commit landed
> `V5__defer_deck_sibling_position.sql` and two `FlywayMigrationTest` assertions: one that
> `condeferrable` is true, and one that performs a real two-row swap inside a transaction — because
> checking the flag is not the same as checking that PostgreSQL then behaves the way the flag
> promises. Removing V5 makes the second test fail on its *first* UPDATE, which is how it was
> verified. This task now starts at the reorder statement itself.

**Files:**
- ~~Create: `memox-api/src/main/resources/db/migration/V5__defer_deck_sibling_position.sql`~~ *(done)*
- Modify: `memox-api/src/main/resources/mybatis/deck_mapper.xml`
- Modify: `memox-api/src/main/java/com/memox/deck/persistence/DeckMapper.java`
- Create: `memox-api/src/main/java/com/memox/deck/service/ReorderDeckCommand.java`
- Modify: `memox-api/src/main/java/com/memox/deck/service/DeckService.java`
- Create: `memox-api/src/main/java/com/memox/deck/dto/request/ReorderDeckRequest.java`
- Modify: `memox-api/src/main/java/com/memox/deck/controller/DeckController.java`
- Modify: `memox-api/src/main/java/com/memox/common/error/ApiErrorCode.java`
- Modify: `memox-api/src/main/resources/messages.properties`, `messages_vi.properties`
- Create: `memox-api/src/test/java/com/memox/deck/DeckReorderTest.java`

**Interfaces:**
- Consumes: `DeckStructureService` (Task 4).
- Produces: `ReorderDeckCommand(String deckId, int targetPosition)`; `DeckService.reorderDeck(ReorderDeckCommand)` → `List<Deck>` (the affected sibling group, in its new order).
- Produces: `ApiErrorCode.DECK_NOT_SIBLING(409, "error.deck-not-sibling")`, `ApiErrorCode.DECK_POSITION_OUT_OF_RANGE(400, "error.deck-position-out-of-range")`.

- [ ] **Step 1: Write the failing test**

```java
class DeckReorderTest extends PostgresIntegrationTest {

	@Autowired DeckService deckService;

	@Test
	void movesADeckDownAndClosesTheGapItLeaves() {
		insertRootDeck("root", "Korean");
		insertSubDeckAt("a", "A", "root", "root", 0);
		insertSubDeckAt("b", "B", "root", "root", 1);
		insertSubDeckAt("c", "C", "root", "root", 2);

		final var group = deckService.reorderDeck(new ReorderDeckCommand("a", 2));

		assertThat(group).extracting(Deck::id).containsExactly("b", "c", "a");
		assertThat(group).extracting(Deck::siblingPosition).containsExactly(0, 1, 2);
	}

	@Test
	void rejectsATargetPositionOutsideTheSiblingGroup() {
		insertRootDeck("root", "Korean");
		insertSubDeckAt("a", "A", "root", "root", 0);

		assertThatThrownBy(() -> deckService.reorderDeck(new ReorderDeckCommand("a", 3)))
				.isInstanceOf(DeckConflictException.class)
				.extracting("errorCode").isEqualTo(ApiErrorCode.DECK_POSITION_OUT_OF_RANGE);
	}

	@Test
	void ignoresSoftDeletedSiblingsWhenRenumbering() {
		insertRootDeck("root", "Korean");
		insertSubDeckAt("a", "A", "root", "root", 0);
		insertSubDeckAt("gone", "Gone", "root", "root", 1);
		insertSubDeckAt("c", "C", "root", "root", 2);
		softDelete("deck", "gone");

		final var group = deckService.reorderDeck(new ReorderDeckCommand("c", 0));

		assertThat(group).extracting(Deck::id).containsExactly("c", "a");   // BR-257, BR-268
	}
}
```

The third test is the one that pins the design decision: a soft-deleted sibling keeps its `sibling_position` row and therefore still occupies a slot in the unique index, but it must not occupy a slot in the **user-visible** order. Renumbering active siblings from `0` upward would collide with the tombstone at `1`. The deferred constraint from Step 3 is what makes the collision transient and legal.

- [ ] **Step 2: Run and verify it fails**

```bash
cd memox-api && ./mvnw.cmd -Dtest=DeckReorderTest test
```

Expected: FAIL — `reorderDeck` does not exist.

- [ ] **Step 3: Add `V5`**

```sql
ALTER TABLE decks DROP CONSTRAINT uq_decks_sibling_scope_position;

ALTER TABLE decks
    ADD CONSTRAINT uq_decks_sibling_scope_position
    UNIQUE (sibling_scope_id, sibling_position) DEFERRABLE INITIALLY DEFERRED;
```

A deferred unique constraint is checked at `COMMIT`, so a reorder may pass through a state where two rows share a position as long as the transaction ends consistent. Two consequences to know: `INSERT … ON CONFLICT` cannot target a deferrable constraint (nothing here does), and a violation now surfaces at commit time, so `ApiExceptionHandler` must keep mapping `DataIntegrityViolationException` to `DATA_INTEGRITY_VIOLATION` — it already does.

Add a `FlywayMigrationTest` assertion that the constraint exists and `condeferrable` is true:

```java
@Test
void deckSiblingPositionUniquenessIsDeferrable() {
    final var deferrable = jdbcTemplate.queryForObject(
            "SELECT condeferrable FROM pg_constraint WHERE conname = 'uq_decks_sibling_scope_position'",
            Boolean.class);
    assertThat(deferrable).isTrue();
}
```

- [ ] **Step 4: Implement the reorder**

```xml
<select id="findSiblingDecksForUpdate" resultMap="deck">
  SELECT id, name, parent_deck_id, root_deck_id, content_type, scheduler_type,
         scheduler_version, scheduler_generation, sibling_position, created_at, updated_at
    FROM decks
   WHERE sibling_scope_id = #{siblingScopeId}
     AND delete_batch_id IS NULL
   ORDER BY sibling_position ASC, id ASC
     FOR UPDATE
</select>

<update id="updateSiblingPosition">
  UPDATE decks SET sibling_position = #{siblingPosition}, updated_at = #{updatedAt}
   WHERE id = #{deckId} AND delete_batch_id IS NULL
</update>
```

`DeckService.reorderDeck` is `@Transactional`: lock the deck, read its group `FOR UPDATE` (BR-268 requires re-reading source and target inside the transaction), reject when `targetPosition` is outside `[0, group.size() - 1]`, rebuild the list with the deck at its new index, then write each row a position.

**CORRECTED — "renumbered densely from `0`" does not work, and this task's own third test is what shows it.** A soft-deleted sibling keeps its `sibling_position` row, so it still holds a slot in `uq_decks_sibling_scope_position` while holding no place in the order a user sees. Renumbering the active siblings from zero walks one of them straight onto the tombstone's slot, and that collision **survives to COMMIT** — a DEFERRABLE constraint makes a *transient* conflict legal, not a final one.

The reorder instead **permutes the positions the active siblings already own**: gather their current positions, sort them, hand them out in the new order. Tombstones keep their slots, the order is dense among active siblings, and the deferred constraint is still required — for the states passed through while the rows are written one at a time.

**The endpoint, which this task never named:** `PUT /api/v1/decks/{deckId}/position`, body `{"targetPosition": n}`, returning the sibling group in its new order. PUT rather than POST because a reorder sets a sub-resource to a value and repeating it changes nothing.

**`DECK_NOT_SIBLING` is NOT added.** With the deck locked before its group is read, its sibling scope cannot change underneath, so no code path can return that error — and an `ApiErrorCode` is a published contract carrying two translations. The impossible case is guarded as an `IllegalStateException`, the same way `AffectedRows` treats a single-row write that matched several.

- [ ] **Step 5: Run the tests and verify they pass**

```bash
cd memox-api && ./mvnw.cmd -Dtest='DeckReorderTest,FlywayMigrationTest' test
```

Expected: PASS, 3 + existing.

- [ ] **Step 6: Commit**

```bash
git add memox-api/src/main/resources/db/migration/V5__defer_deck_sibling_position.sql memox-api/src/main/java/com/memox/deck memox-api/src/main/resources memox-api/src/test/java/com/memox
git commit -m "feat(deck): reorder siblings under a deferred position constraint"
```

---

## Task 6: Deck move, rename, and move targets

**Files:**
- Modify: `memox-api/src/main/resources/mybatis/deck_mapper.xml`
- Modify: `memox-api/src/main/java/com/memox/deck/persistence/DeckMapper.java`
- Create: `memox-api/src/main/java/com/memox/deck/entity/DeckMoveTarget.java`
- Create: `memox-api/src/main/java/com/memox/deck/service/DeckMoveService.java`, `MoveDeckCommand.java`, `RenameDeckCommand.java`
- Modify: `memox-api/src/main/java/com/memox/deck/controller/DeckController.java`
- Create: `memox-api/src/main/java/com/memox/deck/dto/request/MoveDeckRequest.java`, `RenameDeckRequest.java`
- Modify: `memox-api/src/main/java/com/memox/common/error/ApiErrorCode.java`, both `messages*.properties`
- Create: `memox-api/src/test/java/com/memox/deck/DeckMoveTest.java`

**Interfaces:**
- Consumes: `DeckStructureService.depthOf`, `.subtreeHeight`, `.subtreeDeckIds` (Task 4).
- Produces: `MoveDeckCommand(String deckId, String targetParentDeckId)`; `DeckMoveService.move(MoveDeckCommand)` → `Deck`; `DeckMoveService.rename(RenameDeckCommand)` → `Deck`; `DeckMoveService.listCardMoveTargets(String rootDeckId, String sourceDeckId)` → `List<DeckMoveTarget>`.
- Produces: `ApiErrorCode.DECK_CROSS_ROOT_MOVE(409, "error.deck-cross-root-move")`, `DECK_MOVE_INTO_OWN_SUBTREE(409, "error.deck-move-into-own-subtree")`, `SCHEDULER_GENERATION_MISMATCH(409, "error.scheduler-generation-mismatch")`.

Rules enforced inside the write transaction, never above the repository: `depthOf(target) + subtreeHeight(source) <= 10` (BR-55); target must not be inside the source's own subtree; the move is refused across roots whose scheduler type, version or generation differ, and never silently converted (BR-73/74); the source's old parent drops to `unset` if it loses its last active child and the new parent rises to `deck` if it was `unset`, both in the same transaction (BR-163, BR-260).

- [ ] **Step 1: Write the failing test**

```java
class DeckMoveTest extends PostgresIntegrationTest {

	@Autowired DeckMoveService deckMoveService;

	@Test
	void rewritesRootDeckIdForTheWholeMovedSubtree() {
		insertRootDeck("r1", "Korean", SchedulerType.EIGHT_BOX);
		insertRootDeck("r2", "Japanese", SchedulerType.EIGHT_BOX);
		insertSubDeck("a", "Unit 1", "r1", "r1");
		insertSubDeck("b", "Lesson 1", "a", "r1");
		insertSubDeck("target", "Imported", "r2", "r2");

		deckMoveService.move(new MoveDeckCommand("a", "target"));

		assertThat(rootDeckIdOf("a")).isEqualTo("r2");
		assertThat(rootDeckIdOf("b")).isEqualTo("r2");   // updateSubtreeRootDeck reaches every descendant
	}

	@Test
	void refusesAMoveThatWouldMakeAnEleventhLevel() {
		insertChain(10);                       // d1..d10, d1 is the root
		insertRootDeck("r2", "Japanese");
		insertSubDeck("spare", "Spare", "r2", "r2");
		// moving the 2-high subtree d9..d10 under d10 would produce 11
		assertThatThrownBy(() -> deckMoveService.move(new MoveDeckCommand("d9", "d10")))
				.isInstanceOf(DeckConflictException.class)
				.extracting("errorCode").isEqualTo(ApiErrorCode.DECK_DEPTH_EXCEEDED);
	}

	@Test
	void refusesAMoveIntoTheDecksOwnSubtree() {
		insertRootDeck("root", "Korean");
		insertSubDeck("a", "Unit 1", "root", "root");
		insertSubDeck("b", "Lesson 1", "a", "root");

		assertThatThrownBy(() -> deckMoveService.move(new MoveDeckCommand("a", "b")))
				.isInstanceOf(DeckConflictException.class)
				.extracting("errorCode").isEqualTo(ApiErrorCode.DECK_MOVE_INTO_OWN_SUBTREE);
	}

	@Test
	void refusesACrossRootMoveWhenTheGenerationDiffers() {
		insertRootDeck("r1", "Korean", SchedulerType.EIGHT_BOX, /* generation */ 1);
		insertRootDeck("r2", "Japanese", SchedulerType.EIGHT_BOX, /* generation */ 2);
		insertSubDeck("a", "Unit 1", "r1", "r1");
		insertSubDeck("target", "Imported", "r2", "r2");

		assertThatThrownBy(() -> deckMoveService.move(new MoveDeckCommand("a", "target")))
				.isInstanceOf(DeckConflictException.class)
				.extracting("errorCode").isEqualTo(ApiErrorCode.SCHEDULER_GENERATION_MISMATCH);
	}
}
```

- [ ] **Step 2: Run and verify it fails**

```bash
cd memox-api && ./mvnw.cmd -Dtest=DeckMoveTest test
```

Expected: FAIL — `DeckMoveService` does not exist.

- [ ] **Step 3: Port the two statements**

```xml
<update id="updateSubtreeRootDeck">
  UPDATE decks
     SET root_deck_id = #{newRootDeckId}, updated_at = #{updatedAt}
   WHERE id IN (
     WITH RECURSIVE subtree (id) AS (
         SELECT id FROM decks WHERE id = #{deckId}
         UNION
         SELECT d.id FROM decks d INNER JOIN subtree s ON d.parent_deck_id = s.id
     )
     SELECT id FROM subtree
   )
</update>

<update id="reparentDeck">
  UPDATE decks
     SET parent_deck_id = #{parentDeckId},
         sibling_scope_id = #{parentDeckId},
         sibling_position = #{siblingPosition},
         updated_at = #{updatedAt}
   WHERE id = #{deckId} AND delete_batch_id IS NULL
</update>

<select id="findCardMoveTargets" resultType="com.memox.deck.entity.DeckMoveTarget">
  SELECT d.id AS deck_id, d.name AS deck_name, d.content_type AS content_type,
         p.name AS parent_name
    FROM decks d
    LEFT JOIN decks p ON p.id = d.parent_deck_id
   WHERE d.root_deck_id = #{rootDeckId}
     AND d.parent_deck_id IS NOT NULL
     AND d.id &lt;&gt; #{sourceDeckId}
     AND d.delete_batch_id IS NULL
     AND d.content_type IN ('unset', 'card')
   ORDER BY d.name ASC, d.id ASC
</select>
```

`updateSubtreeRootDeck` is copied verbatim from Drift including its deliberate omission of `delete_batch_id IS NULL` inside the recursion — a moved subtree must carry its tombstoned descendants' `root_deck_id` too, or restoring one later would place it under the old root.

`reparentDeck` has no Drift counterpart: Drift stores no `sibling_scope_id`. It is the server-side half of translation row 5, and forgetting it is how a moved deck keeps competing for positions in its **old** parent's scope.

- [ ] **Step 4: Implement the service and endpoints**

`PATCH /api/v1/decks/{deckId}` (rename), `POST /api/v1/decks/{deckId}/move`, `GET /api/v1/decks/{rootDeckId}/card-move-targets`. Rename normalises with `trim()` and validates non-blank / ≤ 200 chars, reusing `ValidationPatterns`.

- [ ] **Step 5: Run the tests and verify they pass**

```bash
cd memox-api && ./mvnw.cmd -Dtest=DeckMoveTest test
```

Expected: PASS, 4 tests.

- [ ] **Step 6: Commit**

```bash
git add memox-api/src/main/java/com/memox/deck memox-api/src/main/resources memox-api/src/test/java/com/memox/deck
git commit -m "feat(deck): move a subtree, rename a deck and list card move targets"
```

---

## Task 7: Card list, filter, sort and counts

Ports `cardListItems`, `cardCount`, `cardIdsMatching`, `flaggedCardsByDeck`, `cardStateCountsByDeck`. Drift compiles `$predicate` and `$order` at build time from Dart expressions; MyBatis builds them from a **whitelist** — never from a client-supplied string (spec: "whitelist-based sorting").

**Files:**
- Create: `memox-api/src/main/java/com/memox/card/entity/CardListItem.java`, `CardFilter.java`, `CardStateCounts.java`
- Create: `memox-api/src/main/java/com/memox/card/service/StageThresholds.java`
- **Do not create `CardSort`.** Wave 3 already shipped `memox-api/src/main/java/com/memox/card/enums/CardSortField.java` implementing `SortField`; extend that enum with the constants this task needs instead of adding a second sort vocabulary.
- Create: `memox-api/src/main/java/com/memox/common/mybatis/UnitSeparatedListTypeHandler.java`
- Modify: `memox-api/src/main/java/com/memox/card/persistence/CardMapper.java`
- Modify: `memox-api/src/main/resources/mybatis/card_mapper.xml`
- Create: `memox-api/src/main/java/com/memox/card/service/CardQueryService.java`
- Create: `memox-api/src/main/java/com/memox/card/dto/response/CardListResponse.java`
- Modify: `memox-api/src/main/java/com/memox/card/controller/CardController.java`
- Create: `memox-api/src/test/java/com/memox/card/CardListTest.java`

**Interfaces:**
- Produces: `CardSort` enum — `CREATED_DESC("c.created_at DESC, c.id DESC")`, `CREATED_ASC("c.created_at ASC, c.id ASC")`, `FRONT_ASC("c.front_folded ASC, c.id ASC")`, `DUE_ASC("s.due_at ASC NULLS LAST, c.id ASC")`, each with `String orderBy()` and a static `fromValue(String)` that throws `IllegalArgumentException` on anything not a constant name. Each constant owns its **literal** ORDER BY fragment; nothing else may reach `${}`.
- Produces: `CardFilter(String deckId, boolean includeSubtree, Boolean flagged, List<String> tagIds, String searchFolded)`, with `CardFilter.ofDeck(String deckId)` and `withTagIds(List<String>)` builders. `flagged` is a boxed `Boolean` on purpose: `null` means "don't filter", which a primitive cannot express.
- Produces: `StageThresholds(int reviewingBox, int masteredBox, int reviewingDays, int masteredDays)` with `StageThresholds.DEFAULTS = new StageThresholds(2, 8, 21, 128)` — the same four numbers `cardStateCountsByDeck` is called with on the Flutter side. They are a constant here, not a literal inside SQL, so changing a stage boundary is one edit rather than four.
- Produces: `UnitSeparatedListTypeHandler extends BaseTypeHandler<List<String>>` — splits the column on `chr(31)` (``) and returns `List.of()` for `null` or an empty string.
- Produces: `CardQueryService.list(CardFilter, CardSort, PageQuery)` → `PagingResponse<CardListItem>`; `.idsMatching(CardFilter, CardSort)` → `List<String>`; `.stateCounts(String deckId, StageThresholds)` → `CardStateCounts`.

- [ ] **Step 1: Write the failing test**

```java
class CardListTest extends PostgresIntegrationTest {

	@Autowired CardQueryService cardQueryService;

	@Test
	void joinsTagNamesInAStableOrder() {
		insertRootDeck("root", "Korean");
		insertSubDeck("deck", "Unit 1", "root", "root");
		insertCardWithState("card-1", "deck", null, null);
		insertTag("t-b", "beta");
		insertTag("t-a", "alpha");
		linkTag("card-1", "t-b");
		linkTag("card-1", "t-a");

		final var page = cardQueryService.list(CardFilter.ofDeck("deck"), CardSort.CREATED_DESC,
				PageQuery.builder().build());

		assertThat(page.getItems()).singleElement()
				.extracting(CardListItem::tagNames)
				.isEqualTo(List.of("alpha", "beta"));   // translation row 1: ORDER BY is not optional
	}

	@Test
	void matchesACardOnceWhenTwoOfItsTagsAreSelected() {
		insertRootDeck("root", "Korean");
		insertSubDeck("deck", "Unit 1", "root", "root");
		insertCardWithState("card-1", "deck", null, null);
		insertTag("t-a", "alpha");
		insertTag("t-b", "beta");
		linkTag("card-1", "t-a");
		linkTag("card-1", "t-b");

		final var filter = CardFilter.ofDeck("deck").withTagIds(List.of("t-a", "t-b"));

		assertThat(cardQueryService.list(filter, CardSort.CREATED_DESC, PageQuery.builder().build()).getTotalItems())
				.isEqualTo(1);   // BR-231 OR-semantics, BR-252 one row per card
	}

	@Test
	void rejectsAnUnknownSortKeyBeforeItReachesSql() {
		assertThatThrownBy(() -> CardSort.fromValue("c.front; DROP TABLE cards"))
				.isInstanceOf(IllegalArgumentException.class);
	}
}
```

- [ ] **Step 2: Run and verify it fails**

```bash
cd memox-api && ./mvnw.cmd -Dtest=CardListTest test
```

Expected: FAIL — `CardQueryService` does not exist.

- [ ] **Step 3: Port the statements**

```xml
<sql id="cardListPredicate">
  c.delete_batch_id IS NULL
  <if test="filter.deckId != null and !filter.includeSubtree">
    AND c.deck_id = #{filter.deckId}
  </if>
  <if test="filter.deckId != null and filter.includeSubtree">
    AND c.deck_id IN (
      WITH RECURSIVE subtree (id) AS (
          SELECT id FROM decks WHERE id = #{filter.deckId} AND delete_batch_id IS NULL
          UNION
          SELECT d.id FROM decks d INNER JOIN subtree s ON d.parent_deck_id = s.id
           WHERE d.delete_batch_id IS NULL
      )
      SELECT id FROM subtree)
  </if>
  <if test="filter.flagged != null">
    AND c.is_flagged = #{filter.flagged}
  </if>
  <if test="filter.searchFolded != null">
    AND (strpos(c.front_folded, #{filter.searchFolded}) &gt; 0
      OR strpos(c.back_folded,  #{filter.searchFolded}) &gt; 0)
  </if>
  <if test="filter.tagIds != null and !filter.tagIds.isEmpty()">
    AND EXISTS (SELECT 1 FROM card_tags ct
                 WHERE ct.card_id = c.id
                   AND ct.tag_id IN
      <foreach collection="filter.tagIds" open="(" separator="," close=")" item="tagId">#{tagId}</foreach>)
  </if>
</sql>

<select id="findCardListItems" resultMap="cardListItem">
  SELECT c.id, c.deck_id, c.front, c.back, c.is_flagged, c.example, c.hint, c.pronunciation,
         c.created_at, c.updated_at,
         s.scheduler_type, s.scheduler_generation, s.learned_at, s.due_at, s.last_answered_at,
         s.answer_count, s.lapse_count, s.current_box, s.ease_factor, s.interval_days, s.repetitions,
         (SELECT string_agg(t.name, chr(31) ORDER BY t.name, t.id)
            FROM card_tags ct
            INNER JOIN tags t ON t.id = ct.tag_id
           WHERE ct.card_id = c.id) AS tag_names
    FROM cards c
    INNER JOIN card_study_states s ON s.card_id = c.id
   WHERE <include refid="cardListPredicate"/>
   <include refid="orderBySlice"/>
   LIMIT #{slice.limit} OFFSET #{slice.offset}
</select>

<select id="countCardListItems" resultType="long">
  SELECT COUNT(*) FROM cards c
   INNER JOIN card_study_states s ON s.card_id = c.id
   WHERE <include refid="cardListPredicate"/>
</select>

<select id="findCardIdsMatching" resultType="java.lang.String">
  SELECT c.id FROM cards c
   INNER JOIN card_study_states s ON s.card_id = c.id
   WHERE <include refid="cardListPredicate"/>
   ORDER BY ${sort.orderBy}
</select>
```

`${sort.orderBy}` is the only `${}` in the whole codebase and it is safe only because `CardSort` is an enum whose fragments are compile-time literals. `CardSort.fromValue` throws on anything else; the controller binds a `CardSort`, never a `String`. `EXISTS` rather than a join is what makes BR-252's "one row per card" true without a `DISTINCT` that would fight the `ORDER BY`.

`tag_names` arrives as one `chr(31)`-separated string; `CardListItem`'s result map binds it through `UnitSeparatedListTypeHandler`, which is also what turns `string_agg`'s `NULL` (a card with no tags) into `List.of()` rather than a null field.

`countCardStatesByDeck` and `findFlaggedCardsByDeck` are direct ports; the four stage thresholds are bound from `StageThresholds`, never written as literals in the XML.

- [ ] **Step 4: Add the endpoint**

`GET /api/v1/cards?deckId=&includeSubtree=&flagged=&tagIds=&q=&sort=&page=&size=` → `PagingResponse<CardListResponse>`.

- [ ] **Step 5: Run and verify it passes**

```bash
cd memox-api && ./mvnw.cmd -Dtest=CardListTest test
```

Expected: PASS, 3 tests.

- [ ] **Step 6: Commit**

```bash
git add memox-api/src/main/java/com/memox/card memox-api/src/main/resources/mybatis/card_mapper.xml memox-api/src/test/java/com/memox/card
git commit -m "feat(card): list, filter and count cards with whitelisted sorting"
```

---

## Task 8: Card detail, study state and review history

Ports `cardById`, `cardDetailById`, `studyStateByCard`, `cardHistoryFirstPage`, `cardHistoryAfter`. History is **read** here; writing it is Phase 3.

**Files:**
- Create: `memox-api/src/main/java/com/memox/card/entity/CardDetail.java`, `CardStudyState.java`, `CardHistoryEntry.java`, `CardHistoryCursor.java`
- Create: `memox-api/src/main/java/com/memox/card/exception/CardNotFoundException.java`
- Modify: `memox-api/src/main/java/com/memox/card/persistence/CardMapper.java`, `card_mapper.xml`
- Modify: `memox-api/src/main/java/com/memox/card/service/CardQueryService.java`
- Create: `memox-api/src/main/java/com/memox/card/dto/response/CardDetailResponse.java`, `CardHistoryResponse.java`
- Modify: `memox-api/src/main/java/com/memox/card/controller/CardController.java`
- Modify: `ApiErrorCode.java`, both `messages*.properties`
- Create: `memox-api/src/test/java/com/memox/card/CardDetailTest.java`

**Interfaces:**
- Produces: `CardQueryService.detail(String cardId)` → `CardDetail`, throwing `CardNotFoundException` when absent or trashed (BR-245).
- Produces: `CardQueryService.history(String cardId, CardHistoryCursor cursor, int limit)` → `List<CardHistoryEntry>`. `CardHistoryCursor(Instant answeredAt, String id)`; `null` cursor means first page.
- Produces: `ApiErrorCode.CARD_NOT_FOUND(404, "error.card-not-found")`.

Keyset pagination, not offset: `cardHistoryAfter`'s `(answered_at, id) < (:answeredAt, :id)` is stable while rows are appended, which offset pagination is not.

- [ ] **Step 1: Write the failing test**

```java
class CardDetailTest extends PostgresIntegrationTest {

	@Autowired CardQueryService cardQueryService;

	@Test
	void pagesHistoryByKeysetAndNotByOffset() {
		seedCardWithThreeAnswers("card-1");   // answered_at t3 > t2 > t1

		final var first = cardQueryService.history("card-1", null, 2);
		assertThat(first).extracting(CardHistoryEntry::id).containsExactly("a3", "a2");

		final var cursor = new CardHistoryCursor(first.get(1).answeredAt(), first.get(1).id());
		assertThat(cardQueryService.history("card-1", cursor, 2))
				.extracting(CardHistoryEntry::id).containsExactly("a1");
	}

	@Test
	void breaksATieOnAnsweredAtByDescendingId() {
		seedTwoAnswersAtTheSameInstant("card-1", "a-lower", "b-higher");

		assertThat(cardQueryService.history("card-1", null, 10))
				.extracting(CardHistoryEntry::id).containsExactly("b-higher", "a-lower");
	}

	@Test
	void refusesToShowATrashedCard() {
		insertRootDeck("root", "Korean");
		insertSubDeck("deck", "Unit 1", "root", "root");
		insertCardWithState("card-1", "deck", null, null);
		softDelete("card", "card-1");

		assertThatThrownBy(() -> cardQueryService.detail("card-1"))
				.isInstanceOf(CardNotFoundException.class);   // BR-245, BR-257
	}
}
```

- [ ] **Step 2: Run and verify it fails**

```bash
cd memox-api && ./mvnw.cmd -Dtest=CardDetailTest test
```

Expected: FAIL — `CardQueryService.history` does not exist.

- [ ] **Step 3: Port the statements**

```xml
<select id="findCardHistoryFirstPage" resultMap="cardHistoryEntry">
  SELECT id, card_id, session_id, scheduler_type, scheduler_generation, kind, mode,
         outcome_reason, used_hint, "action", answered_at, next_due_at,
         previous_box, next_box, previous_ease_factor, next_ease_factor,
         previous_interval_days, next_interval_days, direction
    FROM study_answers
   WHERE card_id = #{cardId}
   ORDER BY answered_at DESC, id DESC
   LIMIT #{limit}
</select>

<select id="findCardHistoryAfter" resultMap="cardHistoryEntry">
  SELECT id, card_id, session_id, scheduler_type, scheduler_generation, kind, mode,
         outcome_reason, used_hint, "action", answered_at, next_due_at,
         previous_box, next_box, previous_ease_factor, next_ease_factor,
         previous_interval_days, next_interval_days, direction
    FROM study_answers
   WHERE card_id = #{cardId}
     AND (answered_at, id) &lt; (#{cursor.answeredAt}, #{cursor.id})
   ORDER BY answered_at DESC, id DESC
   LIMIT #{limit}
</select>
```

The row-value comparison `(answered_at, id) < (…, …)` says exactly what Drift's `answered_at < :x OR (answered_at = :x AND id < :y)` says, in one expression PostgreSQL can drive from `idx_study_answers_card`. `"action"` stays quoted — it is a reserved word and `V2` created the column quoted.

`findCardDetailById` reuses the `string_agg` tag projection from Task 7.

- [ ] **Step 4: Add the endpoints**

`GET /api/v1/cards/{cardId}` and `GET /api/v1/cards/{cardId}/history?answeredAt=&cursorId=&limit=`. `CardNotFoundException extends MemoxException` and carries `CARD_NOT_FOUND`; `ApiExceptionHandler` needs no change because it dispatches on `ApiErrorCode`.

- [ ] **Step 5: Run and verify it passes**

```bash
cd memox-api && ./mvnw.cmd -Dtest=CardDetailTest test
```

Expected: PASS, 3 tests.

- [ ] **Step 6: Commit**

```bash
git add memox-api/src/main/java/com/memox/card memox-api/src/main/resources memox-api/src/test/java/com/memox/card
git commit -m "feat(card): read card detail, study state and keyset-paged history"
```

---

## Task 9: Card edit, flag, and bulk move

Ports `cardDeckContextForIds`, `moveCardsToDeck`, `setCardsFlagByIds`, plus the single-card update the app performs through Drift's generated writer.

**Files:**
- Modify: `memox-api/src/main/java/com/memox/card/persistence/CardMapper.java`, `card_mapper.xml`
- Create: `memox-api/src/main/java/com/memox/card/entity/CardDeckContext.java`
- Create: `memox-api/src/main/java/com/memox/card/exception/CardConflictException.java`
- Create: `memox-api/src/main/java/com/memox/card/service/CardEditService.java`, `CardBulkService.java`, `UpdateCardCommand.java`, `BulkMoveCommand.java`, `BulkFlagCommand.java`
- Create: `memox-api/src/main/java/com/memox/card/dto/request/UpdateCardRequest.java`, `BulkMoveRequest.java`, `BulkFlagRequest.java`
- Modify: `CardController.java`, `ApiErrorCode.java`, both `messages*.properties`
- Create: `memox-api/src/test/java/com/memox/card/CardBulkTest.java`

**Interfaces:**
- Consumes: `IdCollections.requireNonEmpty` (Task 1), `DeckService.prepareCardCreation`'s sibling logic for content-type maintenance.
- Produces: `CardBulkService.move(BulkMoveCommand)` → `int`; `.setFlag(BulkFlagCommand)` → `int`; `CardEditService.update(UpdateCardCommand)` → `Card`.
- Produces: `ApiErrorCode.CARD_CROSS_ROOT_MOVE(409, "error.card-cross-root-move")`, `MOVE_TARGET_INVALID(409, "error.move-target-invalid")`.

BR-165 and BR-166 in one transaction: every card must share the target's root; the target must be non-root with `content_type` in `unset`/`card`; the move writes `deck_id` and `updated_at` only and touches no scheduler column; one violating card rolls the whole batch back; and both the emptied source and the filled target have their `content_type` maintained in the same transaction (BR-163).

- [ ] **Step 1: Write the failing test**

```java
class CardBulkTest extends PostgresIntegrationTest {

	@Autowired CardBulkService cardBulkService;

	@Test
	void movesEveryCardAndLeavesTheEmptiedSourceUnset() {
		insertRootDeck("root", "Korean");
		insertSubDeck("src", "Unit 1", "root", "root", DeckContentType.CARD);
		insertSubDeck("dst", "Unit 2", "root", "root", DeckContentType.UNSET);
		insertCardWithState("c1", "src", null, null);
		insertCardWithState("c2", "src", null, null);

		cardBulkService.move(new BulkMoveCommand(List.of("c1", "c2"), "dst"));

		assertThat(deckIdOf("c1")).isEqualTo("dst");
		assertThat(contentTypeOf("src")).isEqualTo(DeckContentType.UNSET);   // BR-163
		assertThat(contentTypeOf("dst")).isEqualTo(DeckContentType.CARD);
	}

	@Test
	void rollsBackTheWholeBatchWhenOneCardBelongsToAnotherRoot() {
		insertRootDeck("r1", "Korean");
		insertRootDeck("r2", "Japanese");
		insertSubDeck("src", "Unit 1", "r1", "r1", DeckContentType.CARD);
		insertSubDeck("other", "Unit 1", "r2", "r2", DeckContentType.CARD);
		insertSubDeck("dst", "Unit 2", "r1", "r1", DeckContentType.UNSET);
		insertCardWithState("ok", "src", null, null);
		insertCardWithState("foreign", "other", null, null);

		assertThatThrownBy(() -> cardBulkService.move(new BulkMoveCommand(List.of("ok", "foreign"), "dst")))
				.isInstanceOf(CardConflictException.class)
				.extracting("errorCode").isEqualTo(ApiErrorCode.CARD_CROSS_ROOT_MOVE);

		assertThat(deckIdOf("ok")).isEqualTo("src");   // BR-166 all-or-nothing
	}

	@Test
	void setsAndClearsTheFlagExplicitlyRatherThanToggling() {
		insertRootDeck("root", "Korean");
		insertSubDeck("deck", "Unit 1", "root", "root", DeckContentType.CARD);
		insertCardWithState("c1", "deck", null, null);
		insertFlaggedCard("c2", "deck");

		cardBulkService.setFlag(new BulkFlagCommand(List.of("c1", "c2"), true));

		assertThat(flaggedOf("c1")).isTrue();
		assertThat(flaggedOf("c2")).isTrue();   // not a toggle derived from the first card
	}
}
```

- [ ] **Step 2: Run and verify it fails**

```bash
cd memox-api && ./mvnw.cmd -Dtest=CardBulkTest test
```

Expected: FAIL — `CardBulkService` does not exist.

- [ ] **Step 3: Port the statements**

```xml
<select id="findCardDeckContextForIds" resultType="com.memox.card.entity.CardDeckContext">
  SELECT c.id AS card_id, d.id AS deck_id, d.root_deck_id AS root_deck_id,
         d.parent_deck_id AS parent_deck_id, d.content_type AS content_type
    FROM cards c
    INNER JOIN decks d ON d.id = c.deck_id
   WHERE c.id IN
     <foreach collection="cardIds" open="(" separator="," close=")" item="cardId">#{cardId}</foreach>
     AND c.delete_batch_id IS NULL AND d.delete_batch_id IS NULL
</select>

<update id="moveCardsToDeck">
  UPDATE cards SET deck_id = #{deckId}, updated_at = #{updatedAt}
   WHERE id IN
     <foreach collection="cardIds" open="(" separator="," close=")" item="cardId">#{cardId}</foreach>
     AND delete_batch_id IS NULL
</update>

<update id="setCardsFlagByIds">
  UPDATE cards SET is_flagged = #{flagged}, updated_at = #{updatedAt}
   WHERE id IN
     <foreach collection="cardIds" open="(" separator="," close=")" item="cardId">#{cardId}</foreach>
     AND delete_batch_id IS NULL
</update>

<update id="updateCardContent">
  UPDATE cards
     SET front = #{front}, back = #{back},
         front_folded = LOWER(#{front}), back_folded = LOWER(#{back}),
         example = #{example}, hint = #{hint}, pronunciation = #{pronunciation},
         updated_at = #{updatedAt}
   WHERE id = #{id} AND delete_batch_id IS NULL
</update>
```

`#{flagged}` binds a Java `boolean` through Task 1's `BooleanSmallIntTypeHandler` — translation row 6. `updateCardContent` writes content columns only and never touches `is_flagged` or any scheduler column (BR-92).

**Fold parity, verified not assumed.** The Dart side folds with `foldForSearch(raw) => raw.trim().toLowerCase()` (`lib/core/text/search_fold.dart:22`). The service already trims before binding, so `LOWER(#{front})` on a UTF-8 database is the same fold for every script the app ships. Add one test asserting `front_folded` for a mixed-case Korean/Latin string matches the Dart result, so the equivalence is pinned rather than believed.

The service calls `IdCollections.requireNonEmpty(cardIds, "cardIds")` before every one of these — translation row 9.

- [ ] **Step 4: Add the endpoints**

`PATCH /api/v1/cards/{cardId}`, `POST /api/v1/cards/bulk-move`, `POST /api/v1/cards/bulk-flag`.

- [ ] **Step 5: Run and verify it passes**

```bash
cd memox-api && ./mvnw.cmd -Dtest=CardBulkTest test
```

Expected: PASS, 3 tests.

- [ ] **Step 6: Commit**

```bash
git add memox-api/src/main/java/com/memox/card memox-api/src/main/resources memox-api/src/test/java/com/memox/card
git commit -m "feat(card): edit, bulk move and bulk flag cards in one transaction"
```

---

## Task 10: The tag module — catalog, rename, merge, delete

All 13 `tag.drift` statements plus `tagsByFoldedNames`, `tagCountsForCards` and `cardsAlreadyTagged` from `card.drift`. New module: `com.memox.tag`.

**Files:**
- Create: `memox-api/src/main/java/com/memox/tag/entity/Tag.java`, `TagCatalogEntry.java`, `TagName.java`
- Create: `memox-api/src/main/java/com/memox/tag/exception/TagNotFoundException.java`, `TagConflictException.java`
- Create: `memox-api/src/main/java/com/memox/tag/persistence/TagMapper.java`
- Create: `memox-api/src/main/resources/mybatis/tag_mapper.xml`
- Create: `memox-api/src/main/java/com/memox/tag/service/TagCatalogService.java`, `CardTagService.java`, `RenameTagCommand.java`, `AttachTagCommand.java`
- Create: `memox-api/src/main/java/com/memox/tag/controller/TagController.java`
- Create: `memox-api/src/main/java/com/memox/tag/dto/response/TagResponse.java`, `TagCatalogResponse.java`
- Create: `memox-api/src/main/java/com/memox/tag/dto/request/RenameTagRequest.java`, `AttachTagRequest.java`
- Modify: `ApiErrorCode.java`, both `messages*.properties`
- Create: `memox-api/src/test/java/com/memox/tag/TagCatalogTest.java`, `TagMergeTest.java`

**Interfaces:**
- Produces: `TagName.of(String raw)` → `TagName(String value, String folded)`; private constructor, `trim()`, rejects blank, > 50 chars, and any control character (BR-93). Validation lives on the type, so the mapper signature answers "has this been validated?".
- Produces: `TagCatalogService.catalog(String searchFolded)` → `List<TagCatalogEntry>`; `.rename(RenameTagCommand)` → `Tag`; `.delete(String tagId)` → `void`; `.purgeOrphans()` → `int`.
- Produces: `CardTagService.attach(AttachTagCommand)` → `List<Tag>`; `.detach(String cardId, String tagId)`; `.tagsForCards(Collection<String> cardIds)` → `Map<String, List<Tag>>`.
- Produces: `ApiErrorCode.TAG_NOT_FOUND(404, "error.tag-not-found")`, `TAG_LIMIT_EXCEEDED(409, "error.tag-limit-exceeded")`, `TAG_NAME_INVALID(400, "error.tag-name-invalid")`.

- [ ] **Step 1: Write the failing tests**

```java
class TagCatalogTest extends PostgresIntegrationTest {

	@Autowired TagCatalogService tagCatalogService;

	@Test
	void countsOnlyActiveCardsAgainstATag() {
		insertRootDeck("root", "Korean");
		insertSubDeck("deck", "Unit 1", "root", "root", DeckContentType.CARD);
		insertCardWithState("kept", "deck", null, null);
		insertCardWithState("trashed", "deck", null, null);
		insertTag("t-a", "alpha");
		linkTag("kept", "t-a");
		linkTag("trashed", "t-a");
		softDelete("card", "trashed");

		assertThat(tagCatalogService.catalog("")).singleElement()
				.extracting(TagCatalogEntry::cardCount).isEqualTo(1L);   // BR-237
	}

	@Test
	void filtersTheCatalogOnTheFoldedName() {
		insertTag("t-a", "Alpha");
		insertTag("t-b", "Beta");

		assertThat(tagCatalogService.catalog("alp"))
				.extracting(TagCatalogEntry::id).containsExactly("t-a");   // translation row 4
	}
}
```

```java
class TagMergeTest extends PostgresIntegrationTest {

	@Autowired TagCatalogService tagCatalogService;

	@Test
	void mergesIntoTheExistingTagWhenTheFoldedNameCollides() {
		insertRootDeck("root", "Korean");
		insertSubDeck("deck", "Unit 1", "root", "root", DeckContentType.CARD);
		insertCardWithState("c1", "deck", null, null);
		insertCardWithState("c2", "deck", null, null);
		insertTag("src", "Alpha");
		insertTag("dst", "alpha ");     // folds to "alpha" too
		linkTag("c1", "src");
		linkTag("c2", "src");
		linkTag("c2", "dst");           // already carries both

		tagCatalogService.rename(new RenameTagCommand("src", "alpha"));

		assertThat(tagIdsOf("c1")).containsExactly("dst");
		assertThat(tagIdsOf("c2")).containsExactly("dst");   // ON CONFLICT DO NOTHING, row 3
		assertThat(tagExists("src")).isFalse();              // BR-234, one transaction
	}

	@Test
	void deletingATagLeavesEveryCardIntact() {
		insertRootDeck("root", "Korean");
		insertSubDeck("deck", "Unit 1", "root", "root", DeckContentType.CARD);
		insertCardWithState("c1", "deck", null, null);
		insertTag("t-a", "alpha");
		linkTag("c1", "t-a");

		tagCatalogService.delete("t-a");

		assertThat(cardExists("c1")).isTrue();               // BR-235: only card_tags and tags rows go
		assertThat(tagIdsOf("c1")).isEmpty();
	}
}
```

- [ ] **Step 2: Run and verify they fail**

```bash
cd memox-api && ./mvnw.cmd -Dtest='TagCatalogTest,TagMergeTest' test
```

Expected: FAIL — the `com.memox.tag` package does not exist.

- [ ] **Step 3: Port the statements**

```xml
<select id="findTagCatalog" resultType="com.memox.tag.entity.TagCatalogEntry">
  SELECT t.id AS id, t.name AS name,
         (SELECT COUNT(*)
            FROM card_tags ct
            INNER JOIN cards c ON c.id = ct.card_id
           WHERE ct.tag_id = t.id AND c.delete_batch_id IS NULL) AS card_count
    FROM tags t
   WHERE t.owner_id IS NOT DISTINCT FROM #{ownerId}
     AND (#{searchFolded} = '' OR strpos(t.name_folded, #{searchFolded}) &gt; 0)
   ORDER BY t.name_folded ASC, t.id ASC
</select>

<select id="findTagByFoldedName" resultMap="tag">
  SELECT id, name, name_folded, owner_id, created_at
    FROM tags
   WHERE owner_id IS NOT DISTINCT FROM #{ownerId} AND name_folded = #{nameFolded}
</select>

<update id="renameTagById">
  UPDATE tags SET name = #{name}, name_folded = #{nameFolded} WHERE id = #{tagId}
</update>

<insert id="linkCardsOfTagTo">
  INSERT INTO card_tags (card_id, tag_id)
  SELECT ct.card_id, #{targetTagId} FROM card_tags ct WHERE ct.tag_id = #{sourceTagId}
  ON CONFLICT (card_id, tag_id) DO NOTHING
</insert>

<delete id="unlinkAllCardsFromTag">
  DELETE FROM card_tags WHERE tag_id = #{tagId}
</delete>

<delete id="deleteTagById">
  DELETE FROM tags WHERE id = #{tagId}
</delete>

<select id="findOrphanedTags" resultMap="tag">
  SELECT id, name, name_folded, owner_id, created_at
    FROM tags t
   WHERE NOT EXISTS (SELECT 1 FROM card_tags ct WHERE ct.tag_id = t.id)
   ORDER BY created_at ASC, id ASC
</select>
```

**One deliberate divergence, and it is a correctness fix.** Drift's `tagCatalog` counts `card_tags` rows without joining `cards`, so a card sitting in Trash still inflates the tag's count — which BR-237 forbids. The port joins `cards` and filters `delete_batch_id IS NULL`. Record it in Task 15 and raise a WBS entry against the Flutter query.

`orphanedTags` moves from `id NOT IN (SELECT tag_id FROM card_tags)` to `NOT EXISTS`: `NOT IN` against a subquery that can yield `NULL` returns no rows at all in PostgreSQL, and `card_tags.tag_id` being `NOT NULL` today is not a reason to write a statement that breaks if that ever changes.

`renameTagById` is only reached when the folded name does **not** collide. When it does, the service runs `linkCardsOfTagTo` → `unlinkAllCardsFromTag` → `deleteTagById` in the same `@Transactional` method (BR-234).

- [ ] **Step 4: Add the endpoints**

`GET /api/v1/tags?q=`, `PATCH /api/v1/tags/{tagId}`, `DELETE /api/v1/tags/{tagId}`, `POST /api/v1/cards/{cardId}/tags`, `DELETE /api/v1/cards/{cardId}/tags/{tagId}`. Attach enforces the 10-tag ceiling (BR-94) using `countTagsForCard`, and is idempotent when the card already carries the tag (BR-166).

- [ ] **Step 5: Run and verify they pass**

```bash
cd memox-api && ./mvnw.cmd -Dtest='TagCatalogTest,TagMergeTest' test
```

Expected: PASS, 4 tests.

- [ ] **Step 6: Commit**

```bash
git add memox-api/src/main/java/com/memox/tag memox-api/src/main/resources memox-api/src/test/java/com/memox/tag
git commit -m "feat(tag): port the tag catalog, rename-merge and delete"
```

---

## Task 11: Card export and the import duplicate probe

Ports `exportDeckName`, `exportCardsInDeck`, `exportCardsByIds`, `cardKeysInDeck`. The server exposes the **data**; writing a file is the client's job (spec: no device-only side effects).

**Files:**
- Create: `memox-api/src/main/java/com/memox/card/entity/ExportCard.java`, `CardKey.java`, `DeckExport.java`
- Modify: `card_mapper.xml`, `CardMapper.java`
- Create: `memox-api/src/main/java/com/memox/card/service/CardExportService.java`
- Create: `memox-api/src/main/java/com/memox/card/dto/response/ExportResponse.java`
- Modify: `CardController.java`
- Create: `memox-api/src/test/java/com/memox/card/CardExportTest.java`

**Interfaces:**
- Produces: `ExportCard(String cardId, Instant createdAt, String front, String back, String example, String hint, String pronunciation, List<String> tagNames)` — exactly AD-20's six content fields plus the id and creation time (BR-175); no study state, no flag.
- Produces: `CardExportService.exportDeck(String deckId)` → `DeckExport(String deckName, List<ExportCard> cards)`; `.exportCards(String deckId, Collection<String> cardIds)` → `DeckExport`; `.existingKeys(String deckId)` → `Set<CardKey>`.

- [ ] **Step 1: Write the failing test**

```java
class CardExportTest extends PostgresIntegrationTest {

	@Autowired CardExportService cardExportService;

	@Test
	void exportsTheSixContentFieldsAndNothingElse() {
		insertRootDeck("root", "Korean");
		insertSubDeck("deck", "Unit 1", "root", "root", DeckContentType.CARD);
		insertFlaggedCard("c1", "deck");
		insertTag("t-a", "alpha");
		linkTag("c1", "t-a");

		final var export = cardExportService.exportDeck("deck");

		assertThat(export.deckName()).isEqualTo("Unit 1");
		assertThat(export.cards()).singleElement().satisfies(card -> {
			assertThat(card.tagNames()).containsExactly("alpha");
			assertThat(ExportCard.class.getRecordComponents())
					.extracting(java.lang.reflect.RecordComponent::getName)
					.doesNotContain("flagged", "dueAt", "currentBox");   // BR-175
		});
	}

	@Test
	void excludesTrashedCardsFromTheExport() {
		insertRootDeck("root", "Korean");
		insertSubDeck("deck", "Unit 1", "root", "root", DeckContentType.CARD);
		insertCardWithState("kept", "deck", null, null);
		insertCardWithState("trashed", "deck", null, null);
		softDelete("card", "trashed");

		assertThat(cardExportService.exportDeck("deck").cards())
				.extracting(ExportCard::cardId).containsExactly("kept");   // BR-257
	}

	@Test
	void returnsAnEmptyTagListRatherThanNullWhenACardHasNoTags() {
		insertRootDeck("root", "Korean");
		insertSubDeck("deck", "Unit 1", "root", "root", DeckContentType.CARD);
		insertCardWithState("c1", "deck", null, null);

		assertThat(cardExportService.exportDeck("deck").cards())
				.singleElement().extracting(ExportCard::tagNames)
				.isEqualTo(List.of());   // string_agg returns NULL, not ''
	}
}
```

- [ ] **Step 2: Run and verify it fails**

```bash
cd memox-api && ./mvnw.cmd -Dtest=CardExportTest test
```

Expected: FAIL — `CardExportService` does not exist.

- [ ] **Step 3: Port the statements**

```xml
<select id="findExportCardsInDeck" resultMap="exportCard">
  SELECT c.id AS card_id, c.created_at AS created_at, c.front, c.back,
         c.example, c.hint, c.pronunciation,
         (SELECT string_agg(t.name, chr(31) ORDER BY t.name, t.id)
            FROM card_tags ct INNER JOIN tags t ON t.id = ct.tag_id
           WHERE ct.card_id = c.id) AS tag_names
    FROM cards c
   WHERE c.deck_id = #{deckId} AND c.delete_batch_id IS NULL
   ORDER BY c.created_at ASC, c.id ASC
</select>

<select id="findCardKeysInDeck" resultType="com.memox.card.entity.CardKey">
  SELECT front_folded AS front_folded, back_folded AS back_folded
    FROM cards
   WHERE deck_id = #{deckId} AND delete_batch_id IS NULL
</select>
```

`findExportCardsByIds` is the same statement with the `<foreach>` `IN` clause from translation row 9 added. The `exportCard` result map reuses the `UnitSeparatedListTypeHandler` from Task 7, which is what makes the third test pass: `string_agg` over an empty set is `NULL`, and the handler returns `List.of()`.

- [ ] **Step 4: Add the endpoints**

`GET /api/v1/decks/{deckId}/export`, `POST /api/v1/decks/{deckId}/export` (body carries `cardIds`), `GET /api/v1/decks/{deckId}/card-keys`. All three are `@Transactional(readOnly = true)` and log **counts only** (BR-267).

- [ ] **Step 5: Run and verify it passes**

```bash
cd memox-api && ./mvnw.cmd -Dtest=CardExportTest test
```

Expected: PASS, 3 tests.

- [ ] **Step 6: Commit**

```bash
git add memox-api/src/main/java/com/memox/card memox-api/src/main/resources/mybatis/card_mapper.xml memox-api/src/test/java/com/memox/card
git commit -m "feat(card): expose deck export data and the import duplicate probe"
```

---

## Task 12: Trash — soft-delete

New module `com.memox.trash`. Ports `activeSubtreeDeckIds`, `activeCardIdsInDecks`, `markDecksDeleted`, `markCardsDeleted`, plus the `delete_batches` insert.

**Files:**
- Create: `memox-api/src/main/java/com/memox/trash/entity/DeleteBatch.java`
- Create: `memox-api/src/main/java/com/memox/trash/enums/TrashItemType.java`
- Create: `memox-api/src/main/java/com/memox/trash/exception/TrashConflictException.java`
- Create: `memox-api/src/main/java/com/memox/trash/persistence/TrashMapper.java`, `TrashItemTypeTypeHandler.java`
- Create: `memox-api/src/main/resources/mybatis/trash_mapper.xml`
- Create: `memox-api/src/main/java/com/memox/trash/service/TrashDeleteService.java`, `DeleteDeckCommand.java`, `DeleteCardsCommand.java`
- Create: `memox-api/src/main/java/com/memox/trash/controller/TrashController.java`
- Create: `memox-api/src/main/java/com/memox/trash/dto/response/DeleteBatchResponse.java`
- Modify: `ApiErrorCode.java`, both `messages*.properties`
- Create: `memox-api/src/test/java/com/memox/trash/TrashDeleteTest.java`

**Interfaces:**
- Consumes: `DeckStructureService` (Task 4), `IdCollections` (Task 1).
- Produces: `DeleteBatch(String id, TrashItemType itemType, String rootItemId, Instant deletedAt)`.
- Produces: `TrashDeleteService.deleteDeck(DeleteDeckCommand)` → `DeleteBatch`; `.deleteCards(DeleteCardsCommand)` → `DeleteBatch`.

BR-256/258/260 in one transaction: exactly one batch row with one `deleted_at`; every **active** descendant deck and card is stamped with it; a descendant already tombstoned from an earlier batch keeps its old batch and is not absorbed; and a non-root parent that just lost its last active direct child drops to `unset`.

- [ ] **Step 1: Write the failing test**

```java
class TrashDeleteTest extends PostgresIntegrationTest {

	@Autowired TrashDeleteService trashDeleteService;

	@Test
	void stampsTheWholeActiveSubtreeWithOneBatchAndOneInstant() {
		insertRootDeck("root", "Korean");
		insertSubDeck("a", "Unit 1", "root", "root");
		insertSubDeck("b", "Lesson 1", "a", "root", DeckContentType.CARD);
		insertCardWithState("c1", "b", null, null);

		final var batch = trashDeleteService.deleteDeck(new DeleteDeckCommand("a"));

		assertThat(batchIdOfDeck("a")).isEqualTo(batch.id());
		assertThat(batchIdOfDeck("b")).isEqualTo(batch.id());
		assertThat(batchIdOfCard("c1")).isEqualTo(batch.id());   // BR-258
	}

	@Test
	void leavesAnEarlierTombstoneInItsOriginalBatch() {
		insertRootDeck("root", "Korean");
		insertSubDeck("a", "Unit 1", "root", "root");
		insertSubDeck("b", "Lesson 1", "a", "root", DeckContentType.CARD);
		insertCardWithState("old", "b", null, null);
		final var first = trashDeleteService.deleteCards(new DeleteCardsCommand(List.of("old")));

		final var second = trashDeleteService.deleteDeck(new DeleteDeckCommand("a"));

		assertThat(batchIdOfCard("old")).isEqualTo(first.id());   // BR-258, not absorbed
		assertThat(batchIdOfDeck("a")).isEqualTo(second.id());
	}

	@Test
	void returnsTheEmptiedParentToUnset() {
		insertRootDeck("root", "Korean");
		insertSubDeck("a", "Unit 1", "root", "root", DeckContentType.CARD);
		insertCardWithState("only", "a", null, null);

		trashDeleteService.deleteCards(new DeleteCardsCommand(List.of("only")));

		assertThat(contentTypeOf("a")).isEqualTo(DeckContentType.UNSET);   // BR-260
	}

	@Test
	void keepsTheRootDeckAsDeckEvenWhenItIsEmptied() {
		insertRootDeck("root", "Korean");
		insertSubDeck("a", "Unit 1", "root", "root");

		trashDeleteService.deleteDeck(new DeleteDeckCommand("a"));

		assertThat(contentTypeOf("root")).isEqualTo(DeckContentType.DECK);   // BR-58
	}
}
```

- [ ] **Step 2: Run and verify it fails**

```bash
cd memox-api && ./mvnw.cmd -Dtest=TrashDeleteTest test
```

Expected: FAIL — the `com.memox.trash` package does not exist.

- [ ] **Step 3: Port the statements**

```xml
<insert id="insertDeleteBatch" parameterType="com.memox.trash.entity.DeleteBatch">
  INSERT INTO delete_batches (id, item_type, root_item_id, deleted_at)
  VALUES (#{id},
          #{itemType,typeHandler=com.memox.trash.persistence.TrashItemTypeTypeHandler},
          #{rootItemId}, #{deletedAt})
</insert>

<select id="findActiveSubtreeDeckIds" resultType="java.lang.String">
  WITH RECURSIVE subtree (id) AS (
      SELECT id FROM decks WHERE id = #{deckId} AND delete_batch_id IS NULL
      UNION
      SELECT d.id FROM decks d INNER JOIN subtree s ON d.parent_deck_id = s.id
       WHERE d.delete_batch_id IS NULL
  )
  SELECT id FROM subtree
</select>

<select id="findActiveCardIdsInDecks" resultType="java.lang.String">
  SELECT id FROM cards
   WHERE deck_id IN
     <foreach collection="deckIds" open="(" separator="," close=")" item="deckId">#{deckId}</foreach>
     AND delete_batch_id IS NULL
</select>

<update id="markDecksDeleted">
  UPDATE decks SET delete_batch_id = #{batchId}, updated_at = #{updatedAt}
   WHERE id IN
     <foreach collection="deckIds" open="(" separator="," close=")" item="deckId">#{deckId}</foreach>
     AND delete_batch_id IS NULL
</update>

<update id="markCardsDeleted">
  UPDATE cards SET delete_batch_id = #{batchId}, updated_at = #{updatedAt}
   WHERE id IN
     <foreach collection="cardIds" open="(" separator="," close=")" item="cardId">#{cardId}</foreach>
     AND delete_batch_id IS NULL
</update>
```

The `AND delete_batch_id IS NULL` on both `UPDATE`s is what makes the second test pass — it is Drift's own guard and it is the whole of BR-258's "keeps its old tombstone".

- [ ] **Step 4: Add the endpoints**

`DELETE /api/v1/decks/{deckId}` and `POST /api/v1/cards/bulk-delete` both return `201` with the `DeleteBatchResponse`, because a soft-delete **creates** a batch resource. Neither logs a name or a card face.

- [ ] **Step 5: Run and verify it passes**

```bash
cd memox-api && ./mvnw.cmd -Dtest=TrashDeleteTest test
```

Expected: PASS, 4 tests.

- [ ] **Step 6: Commit**

```bash
git add memox-api/src/main/java/com/memox/trash memox-api/src/main/resources memox-api/src/test/java/com/memox/trash
git commit -m "feat(trash): soft-delete a deck subtree or a batch of cards"
```

---

## Task 13: Trash — list and restore

Ports `trashBatchRows`, `batchById`, `batchDeckIds`, `batchCardIds`, `tombstoneDeckInBatch`, `tombstoneCardInBatch`, `anyDeckById`, `batchSubtreeHeightProbe`, `restoreDecksInBatch`, `restoreCardsInBatch`.

**A design decision this task must settle, surfaced by the schema.** `V5`'s unique `(sibling_scope_id, sibling_position)` still covers tombstoned decks, so a restored deck's old position may now be occupied by a sibling created after the delete. BR-262 requires the rows to come back unchanged; it says nothing about the position, and BR-261/263 make the **target** an explicit user choice. Resolution: restore reassigns `sibling_position` to the next free slot in the chosen target scope, and leaves every other column untouched. The alternative — failing the restore — would make the deferred constraint from Task 5 a user-facing error, which is the wrong place for it.

**Files:**
- Modify: `trash_mapper.xml`, `TrashMapper.java`
- Create: `memox-api/src/main/java/com/memox/trash/entity/TrashBatchRow.java`
- Create: `memox-api/src/main/java/com/memox/trash/enums/TrashOrigin.java`
- Create: `memox-api/src/main/java/com/memox/trash/service/TrashRestoreService.java`, `RestoreBatchCommand.java`
- Modify: `TrashController.java`, `ApiErrorCode.java`, both `messages*.properties`
- Create: `memox-api/src/test/java/com/memox/trash/TrashRestoreTest.java`

**Interfaces:**
- Consumes: `DeckStructureService.depthOf`, `DeckMapper.nextSiblingPosition`.
- Produces: `TrashBatchRow(String batchId, TrashItemType itemType, Instant deletedAt, String itemName, String originDeckId, String originDeckName, long batchDeckCount, long batchCardCount, List<DeckAncestor> originPath)`.
- Produces: `TrashRestoreService.list()` → `List<TrashBatchRow>`; `.restore(RestoreBatchCommand)` → `int`.
- Produces: `ApiErrorCode.RESTORE_TARGET_INVALID(409, "error.restore-target-invalid")`, `BATCH_NOT_FOUND(404, "error.batch-not-found")`.

- [ ] **Step 1: Write the failing test**

```java
class TrashRestoreTest extends PostgresIntegrationTest {

	@Autowired TrashDeleteService trashDeleteService;
	@Autowired TrashRestoreService trashRestoreService;

	@Test
	void revivesOnlyTheRowsOfTheChosenBatch() {
		insertRootDeck("root", "Korean");
		insertSubDeck("a", "Unit 1", "root", "root", DeckContentType.CARD);
		insertCardWithState("c1", "a", null, null);
		insertCardWithState("c2", "a", null, null);
		final var first = trashDeleteService.deleteCards(new DeleteCardsCommand(List.of("c1")));
		trashDeleteService.deleteCards(new DeleteCardsCommand(List.of("c2")));

		trashRestoreService.restore(new RestoreBatchCommand(first.id(), "a"));

		assertThat(batchIdOfCard("c1")).isNull();
		assertThat(batchIdOfCard("c2")).isNotNull();   // BR-262
	}

	@Test
	void givesARestoredDeckAFreePositionWhenItsOldOneIsTaken() {
		insertRootDeck("root", "Korean");
		insertSubDeckAt("a", "A", "root", "root", 0);
		final var batch = trashDeleteService.deleteDeck(new DeleteDeckCommand("a"));
		insertSubDeckAt("b", "B", "root", "root", 1);

		trashRestoreService.restore(new RestoreBatchCommand(batch.id(), "root"));

		assertThat(siblingPositionOf("a")).isEqualTo(2);
		assertThat(siblingPositionOf("b")).isEqualTo(1);   // untouched
	}

	@Test
	void refusesARestoreThatWouldExceedTenLevels() {
		insertChain(10);
		final var batch = trashDeleteService.deleteDeck(new DeleteDeckCommand("d10"));

		assertThatThrownBy(() -> trashRestoreService.restore(new RestoreBatchCommand(batch.id(), "d10")))
				.isInstanceOf(TrashConflictException.class)
				.extracting("errorCode").isEqualTo(ApiErrorCode.RESTORE_TARGET_INVALID);   // BR-261
	}

	@Test
	void reportsAnEmptyOriginPathForATopLevelItem() {
		insertRootDeck("root", "Korean");
		insertSubDeck("a", "Unit 1", "root", "root");
		trashDeleteService.deleteDeck(new DeleteDeckCommand("a"));

		assertThat(trashRestoreService.list()).singleElement()
				.extracting(TrashBatchRow::originPath).isEqualTo(List.of());   // translation row 2
	}
}
```

- [ ] **Step 2: Run and verify it fails**

```bash
cd memox-api && ./mvnw.cmd -Dtest=TrashRestoreTest test
```

Expected: FAIL — `TrashRestoreService` does not exist.

- [ ] **Step 3: Port the statements**

```xml
<select id="findTrashBatchRows" resultMap="trashBatchRow">
  WITH RECURSIVE ancestry (deck_id, node_id, distance) AS (
      SELECT id, parent_deck_id, 1 FROM decks WHERE parent_deck_id IS NOT NULL
      UNION
      SELECT a.deck_id, d.parent_deck_id, a.distance + 1
        FROM decks d INNER JOIN ancestry a ON d.id = a.node_id
       WHERE d.parent_deck_id IS NOT NULL
  )
  SELECT b.id AS batch_id, b.item_type AS item_type, b.deleted_at AS deleted_at,
         COALESCE(d.name, c.front) AS item_name,
         CASE WHEN b.item_type = 'deck' THEN d.parent_deck_id ELSE c.deck_id END AS origin_deck_id,
         (SELECT COUNT(*) FROM decks bd WHERE bd.delete_batch_id = b.id) AS batch_deck_count,
         (SELECT COUNT(*) FROM cards bc WHERE bc.delete_batch_id = b.id) AS batch_card_count,
         (SELECT COALESCE(json_agg(json_build_object('id', a.node_id, 'name', ad.name,
                                                     'distance', a.distance)
                                   ORDER BY a.distance), '[]'::json)
            FROM ancestry a
            INNER JOIN decks ad ON ad.id = a.node_id
           WHERE a.deck_id = CASE WHEN b.item_type = 'deck' THEN d.parent_deck_id
                                  ELSE c.deck_id END) AS origin_path_json,
         (SELECT od.name FROM decks od
           WHERE od.id = CASE WHEN b.item_type = 'deck' THEN d.parent_deck_id
                              ELSE c.deck_id END) AS origin_deck_name
    FROM delete_batches b
    LEFT JOIN decks d ON b.item_type = 'deck' AND d.id = b.root_item_id
    LEFT JOIN cards c ON b.item_type = 'card' AND c.id = b.root_item_id
   ORDER BY b.deleted_at DESC, b.id DESC
</select>
```

Three things this statement gets right that are easy to lose. The `ancestry` CTE walks **every** deck, not just the batch's — it has to, because the origin of a trashed item is a deck that may itself be trashed. `origin_path_json` goes through translation row 2, so a top-level item yields `[]` and not `null`. And `COALESCE(d.name, c.front)` returns a card face: it is sent to the owner in the response and **never** written to a log (BR-267).

```xml
<update id="restoreDecksInBatch">
  UPDATE decks SET delete_batch_id = NULL, updated_at = #{updatedAt}
   WHERE delete_batch_id = #{batchId}
</update>

<update id="restoreCardsInBatch">
  UPDATE cards SET delete_batch_id = NULL, updated_at = #{updatedAt}
   WHERE delete_batch_id = #{batchId}
</update>

<select id="probeBatchSubtreeHeight" resultType="java.lang.Integer">
  WITH RECURSIVE walk (id, height) AS (
      SELECT id, 1 FROM decks WHERE id = #{deckId} AND delete_batch_id = #{batchId}
      UNION ALL
      SELECT d.id, w.height + 1
        FROM decks d INNER JOIN walk w ON d.parent_deck_id = w.id
       WHERE d.delete_batch_id = #{batchId} AND w.height &lt; #{maxWalk}
  )
  SELECT MAX(height) FROM walk
</select>
```

`TrashRestoreService.restore` is `@Transactional`: load the batch (404 if absent), validate the target against BR-261 using `depthOf(target) + probeBatchSubtreeHeight(root, batch) <= 10`, reparent the batch's root item into the target with a fresh `sibling_position`, run both restore updates, delete the batch row, then maintain `content_type` on the target (BR-163).

- [ ] **Step 4: Add the endpoints**

`GET /api/v1/trash` and `POST /api/v1/trash/{batchId}/restore`.

- [ ] **Step 5: Run and verify it passes**

```bash
cd memox-api && ./mvnw.cmd -Dtest=TrashRestoreTest test
```

Expected: PASS, 4 tests.

- [ ] **Step 6: Commit**

```bash
git add memox-api/src/main/java/com/memox/trash memox-api/src/main/resources memox-api/src/test/java/com/memox/trash
git commit -m "feat(trash): list batches and restore one into a chosen target"
```

---

## Task 14: Trash — retention purge

Ports `eligibleBatches`, `purgeBlockerCount`, `purgeBatch`. Retention is 30 × 24 h from `deleted_at`, and the exact boundary is eligible (BR-264).

**Files:**
- Create: `memox-api/src/main/resources/db/migration/V6__add_trash_indexes.sql`
- Modify: `trash_mapper.xml`, `TrashMapper.java`
- Create: `memox-api/src/main/java/com/memox/trash/service/TrashPurgeService.java`, `RetentionPolicy.java`, `PurgeReport.java`
- Modify: `TrashController.java`
- Create: `memox-api/src/test/java/com/memox/trash/TrashPurgeTest.java`

**Interfaces:**
- Produces: `RetentionPolicy.RETENTION = Duration.ofDays(30)`; `RetentionPolicy.cutoff(Instant now)` → `now.minus(RETENTION)`.
- Produces: `TrashPurgeService.purgeExpired()` → `PurgeReport(int purgedBatches, int skippedBatches)`; idempotent, safe to call on every request that opens Trash.

- [ ] **Step 1: Write the failing test**

```java
class TrashPurgeTest extends PostgresIntegrationTest {

	@Autowired TrashPurgeService trashPurgeService;
	@Autowired TrashDeleteService trashDeleteService;

	@Test
	void purgesABatchExactlyAtTheThirtyDayBoundary() {
		insertRootDeck("root", "Korean");
		insertSubDeck("a", "Unit 1", "root", "root", DeckContentType.CARD);
		insertCardWithState("c1", "a", null, null);
		final var batch = trashDeleteService.deleteCards(new DeleteCardsCommand(List.of("c1")));
		backdateBatch(batch.id(), Duration.ofDays(30));   // deleted_at == cutoff

		assertThat(trashPurgeService.purgeExpired().purgedBatches()).isEqualTo(1);   // BR-264: >= is eligible
		assertThat(cardExists("c1")).isFalse();
	}

	@Test
	void skipsABatchWhoseSubtreeStillHoldsAnActiveRow() {
		insertRootDeck("root", "Korean");
		insertSubDeck("a", "Unit 1", "root", "root");
		insertSubDeck("b", "Lesson 1", "a", "root", DeckContentType.CARD);
		final var batch = trashDeleteService.deleteDeck(new DeleteDeckCommand("a"));
		reviveDeckWithoutBatch("b");                       // simulates a partial restore
		backdateBatch(batch.id(), Duration.ofDays(31));

		final var report = trashPurgeService.purgeExpired();

		assertThat(report.purgedBatches()).isZero();
		assertThat(report.skippedBatches()).isEqualTo(1);   // BR-265
		assertThat(deckExists("a")).isTrue();
	}

	@Test
	void isIdempotentWhenNothingIsEligible() {
		assertThat(trashPurgeService.purgeExpired().purgedBatches()).isZero();
		assertThat(trashPurgeService.purgeExpired().purgedBatches()).isZero();
	}
}
```

- [ ] **Step 2: Run and verify it fails**

```bash
cd memox-api && ./mvnw.cmd -Dtest=TrashPurgeTest test
```

Expected: FAIL — `TrashPurgeService` does not exist.

- [ ] **Step 3: Port the statements and add `V6`**

```sql
CREATE INDEX idx_cards_deck_active ON cards (deck_id) WHERE delete_batch_id IS NULL;
CREATE INDEX idx_decks_parent_active ON decks (parent_deck_id) WHERE delete_batch_id IS NULL;
```

Both partial indexes serve the "active children of this deck" question that Tasks 2, 4, 12 and 14 all ask, and which `idx_decks_parent_position` cannot answer without also reading the tombstones. Add them only after measuring with `EXPLAIN (ANALYZE, BUFFERS)` on a seeded 10 000-deck / 100 000-card database; if the plan does not change, drop this migration rather than shipping an index nothing uses.

```xml
<select id="findEligibleBatches" resultMap="deleteBatch">
  SELECT id, item_type, root_item_id, deleted_at
    FROM delete_batches
   WHERE deleted_at &lt;= #{cutoff}
   ORDER BY deleted_at ASC, id ASC
</select>

<select id="countPurgeBlockers" resultType="long">
  WITH RECURSIVE subtree (id) AS (
      SELECT id FROM decks WHERE delete_batch_id = #{batchId}
      UNION
      SELECT d.id FROM decks d INNER JOIN subtree s ON d.parent_deck_id = s.id
  )
  SELECT (SELECT COUNT(*) FROM decks d
            WHERE d.id IN (SELECT id FROM subtree)
              AND (d.delete_batch_id IS NULL
                OR d.delete_batch_id NOT IN
                   <foreach collection="allowedBatchIds" open="(" separator="," close=")" item="allowedId">#{allowedId}</foreach>))
       + (SELECT COUNT(*) FROM cards c
            WHERE c.deck_id IN (SELECT id FROM subtree)
              AND (c.delete_batch_id IS NULL
                OR c.delete_batch_id NOT IN
                   <foreach collection="allowedBatchIds" open="(" separator="," close=")" item="allowedId">#{allowedId}</foreach>))
</select>

<delete id="purgeBatch">
  DELETE FROM delete_batches WHERE id = #{batchId}
</delete>
```

`purgeBatch` deletes only the batch row; every tombstoned deck and card carries `delete_batch_id … ON DELETE CASCADE`, so the rows and their `card_study_states`, `study_answers`, `study_queue_items` and `card_tags` follow through the FK graph (BR-265). Assert that in the first test rather than assuming it.

`allowedBatchIds` is the eligible set computed in the same call, so `IdCollections.requireNonEmpty` guards it before the statement runs.

- [ ] **Step 4: Wire the trigger points**

`purgeExpired()` runs at the start of `GET /api/v1/trash` and is exposed as `POST /api/v1/trash/purge-expired` for the client's startup and resume hooks (BR-264). No scheduler bean — the server does not own the app lifecycle.

- [ ] **Step 5: Run and verify it passes**

```bash
cd memox-api && ./mvnw.cmd -Dtest='TrashPurgeTest,FlywayMigrationTest' test
```

Expected: PASS, 3 + existing.

- [ ] **Step 6: Commit**

```bash
git add memox-api/src/main/resources/db/migration/V6__add_trash_indexes.sql memox-api/src/main/java/com/memox/trash memox-api/src/main/resources/mybatis/trash_mapper.xml memox-api/src/test/java/com/memox/trash
git commit -m "feat(trash): purge batches past the thirty-day retention window"
```

---

## Task 15: The parity document, the OpenAPI snapshot and the WBS

**Files:**
- Create: `docs/superpowers/specs/2026-09-09-drift-to-mybatis-parity.md`
- Create: `memox-api/src/test/java/com/memox/contract/DriftParityTest.java`
- Modify: `memox-api/src/test/java/com/memox/contract/OpenApiContractTest.java`
- Regenerate: `memox-api/openapi.json` *(via `OpenApiSnapshotTest`; do not hand-edit)*
- Modify: `memox-api/src/test/java/com/memox/architecture/LayerArchitectureTest.java`
- Modify: `docs/wbs.md`

**Interfaces:**
- Produces: the parity document — one row per ported statement: Drift name, MyBatis id, translation rows applied, and **every deliberate divergence with its reason**. It is the answer to "was this SQL ported faithfully?" that reading 69 statements cannot give.

- [ ] **Step 1: Write the failing test**

```java
class DriftParityTest {

	private static final Path DRIFT_QUERIES = Path.of("..", "lib", "core", "database", "queries");
	private static final Set<String> PHASE_2_FILES = Set.of("deck.drift", "card.drift", "tag.drift", "trash.drift");
	private static final Set<String> DEFERRED = Set.of("resetTreeStudyStates");

	@Test
	void everyPhase2DriftQueryIsAccountedForInTheParityDocument() throws IOException {
		final var accountedFor = new HashSet<>(parityDocumentQueryNames());
		accountedFor.addAll(DEFERRED);

		final var declared = driftQueryNames();
		assertThat(declared).isNotEmpty();

		final var missing = new TreeSet<>(declared);
		missing.removeAll(accountedFor);
		assertThat(missing).as("Drift queries with no parity row").isEmpty();
	}

	@Test
	void everyDocumentedStatementExistsInAMapperXml() throws IOException {
		final var mapperIds = mapperStatementIds();
		assertThat(parityDocumentStatementIds()).isSubsetOf(mapperIds);
	}
}
```

This is the test that makes the mapping a **checked** artifact instead of a claim. Adding a Drift query later without a parity row turns the suite red, which is the only mechanism that keeps this document true after the branch merges.

- [ ] **Step 2: Run and verify it fails**

```bash
cd memox-api && ./mvnw.cmd -Dtest=DriftParityTest test
```

Expected: FAIL — the parity document does not exist.

- [ ] **Step 3: Write the parity document**

One table with the 68 ported statements (69 minus the deferred `resetTreeStudyStates`), plus a **Deliberate divergences** section recording the four found while porting:

1. `rootDeckSummaries.nextDueAt` — Drift's sub-select is uncorrelated and returns the same instant for every root deck; the port correlates it on `nd.root_deck_id = d.id`.
2. `childDeckLevel.nextDueAt` — the same defect on the level view; the port adds `fb.branch_id = child.id`.
3. `tagCatalog.cardCount` — Drift counts `card_tags` rows without excluding trashed cards, which BR-237 forbids; the port joins `cards`.
4. `orphanedTags` — `NOT IN` becomes `NOT EXISTS`, because `NOT IN` over a nullable subquery returns nothing in PostgreSQL.
5. `nextSiblingPosition` — Drift filters `delete_batch_id IS NULL`; the server must not, because `uq_decks_sibling_scope_position` covers tombstones too.

Each divergence names the BR it serves and, for 1–3, gets a WBS entry against the Flutter query so the client is fixed rather than the server quietly disagreeing with it.

- [ ] **Step 4: Extend the contract and architecture tests**

Add to `OpenApiContractTest` an assertion that every new path is published under `/api/v1` and that each documents its `409` Problem Details response.

**Both architecture rules that used to live in this step have moved to Task 1 and are already
live.** Adding them here would have been too late to matter: a rule introduced after tag and trash
are built can only report what was already written, and the whole point of `CardService → DeckMapper`
being illegal is that nobody writes it in the first place.

Two things changed in the move, and both were found by injecting a fault rather than by reading:

- `sqlLivesOnlyInMapperXml` is `noMethods().that().areDeclaredInClassesThat()…`, not `noClasses()`.
  MyBatis puts `@Select` on the **method**, so the class-level form drafted here compiles, reads
  correctly and can never fire — a rule that would have passed green for the rest of the project.
- `featuresDoNotReachEachOthersPersistence` is now `featuresDoNotReachEachOthersInternals`, and its
  allowance is wider than "service-to-service" because service-to-service is not expressible on its
  own: `DeckService.prepareCardCreation` returns a `DeckSchedulerState` and a `SchedulerType`, so
  `CardService` *necessarily* depends on `deck.entity` and `deck.enums`. The published surface is
  therefore service + entity + enums + exception, reachable only **from** a `..service..` package.
  Another feature's `persistence`, `controller` and `dto` stay closed to everyone.

**Snapshot ownership.** This step's Files list still names `OpenApiContractTest`. That class is a
smoke test over four paths; the byte-for-byte snapshot is owned by `OpenApiSnapshotTest`, which
M9.W1 added along with `memox-api/openapi.json` and the
`./mvnw -Dmemox.openapi.write=true -Dtest=OpenApiSnapshotTest test` regeneration command. New paths
need no change to that class — regenerate the snapshot and commit the diff, because **that diff is
the contract change**.

- [ ] **Step 5: Run the whole suite and the docs gate**

```bash
cd memox-api && ./mvnw.cmd test
```

```bash
py -3 .claude/skills/flutter-workflow/scripts/check_docs.py --quiet
```

Expected: all backend tests pass; the document contract stays valid.

- [ ] **Step 6: Update the WBS and commit**

Add the Phase 2 rows to `docs/wbs.md` — one per task, marked done, with the divergence follow-ups recorded as open Flutter-side entries. Flip the plan header's `Status` to `complete`.

```bash
git add docs/superpowers memox-api/src/test docs/wbs.md
git commit -m "docs(api): record the Drift to MyBatis parity contract for phase 2"
```

---

## 7. Deliberately out of scope

Named here so a later reader can tell "not done" from "decided against".

| Drift queries | Where they belong | Why not now |
|---|---|---|
| `resetTreeStudyStates` (deck.drift) | **Phase 3** | The spec assigns "scheduler selection/reset" to Phase 3. Reset increments `scheduler_generation`, which every study write must then be checked against; shipping the reset without the check it protects is worse than shipping neither. |
| `study.drift` — 21 queries | **Phase 3** | Session lifecycle, queue serving, answer recording, append-only history writes. |
| `search.drift` — 1 query | **Phase 4** | Library search with keyset pagination across four fields (BR-247, BR-252). |
| `progress.drift` — 3 queries | **Phase 4** | Overview and per-deck activity reads. |
| `settings.drift` — 5 queries | **Phase 4** | Persisted global settings. |
| `reminder.drift` — 3 queries | **Phase 4** | `reminderWorkloadPerRootDeck` is a server-computable read; the notification scheduling it feeds is device-only and stays on the client. |

Also out of scope, and not a gap: auth (`owner_id` stays `NULL`), sync bookkeeping, and any endpoint that would write a file on the server.

---

## 8. Definition of Done

- All 68 in-scope Drift statements have a MyBatis statement, a parity row, and at least one test that exercises them against a real PostgreSQL.
- `./mvnw test` is green — every test, not a selected subset — on both test backends (Testcontainers where Docker exists, local PostgreSQL otherwise).
- `V5` and `V6` apply cleanly from an **empty** database, and `FlywayMigrationTest` asserts the deferrable constraint and the two partial indexes.
- Every new failure has an `ApiErrorCode`, an English message and a Vietnamese message, and is reachable in a controller test asserting the Problem Details body.
- `LayerArchitectureTest` passes including the two new rules; no `@Select`/`@Insert`/`@Update`/`@Delete` annotation exists anywhere.
- `OpenApiSnapshotTest` passes against the committed `openapi.json`, and that snapshot is regenerated in the same commit as any path change. `OpenApiContractTest` stays what it is — a smoke test that the four original paths and `info.title` are still published.
- No endpoint, service or mapper logs card content, tag names, deck names, history or export payloads at any level.
- `docs/wbs.md` carries one row per task, and the five divergences are recorded with their Flutter-side follow-ups.
- `py -3 .claude/skills/flutter-workflow/scripts/check_docs.py --quiet` is clean.

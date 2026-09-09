# memox-api — Spring Boot standards audit

| | |
|---|---|
| Base commit | `ba6f7928` (`main`) — *the ledger keeps the living work* (M100.65) |
| Scope | Every file under `memox-api/`: 41 main Java files (1 177 lines), 14 test files (813 lines), 2 mapper XML, 4 Flyway migrations, `pom.xml`, and the four `.github/workflows/` files |
| Rubric | `~/.claude/skills/spring-boot-rest-api/references/review-checklist.md`, plus the reference files it delegates to · `~/.claude/skills/spring-boot-harness` |
| Mode | **REPORT ONLY.** No source file was modified. Scope decisions are the owner's; §7 lists the two that this audit deliberately does not make. |
| Method | Every Java file read in full. Every claim below carries a `file:line` or a command whose output is quoted. Claims that could not be verified were dropped, not softened — §6 lists the seven that were. |
| Last updated | 2026-09-09 |

`memox-api` has **no `CLAUDE.md` or `AGENTS.md` of its own** (`find memox-api -maxdepth 2 -iname 'CLAUDE.md' -o -iname 'AGENTS.md'` → empty). Under the global priority order, that makes the `spring-boot-rest-api` skill the governing standard for this module, ahead of generic preference and behind only the repo-level contract. That is why this audit measures against it rather than against taste.

---

## 1. Verdict

The code that exists is **better than the average Spring Boot module of this age**, and that is worth saying before the findings: the layering is correct, SQL is where the standard demands, Problem Details are centralised and internationalised, enums are real enums with type handlers, records are used for DTOs, and a concurrency test exists for the one place where a race was plausible.

What is missing is not craft. It is **enforcement**. Every standard this audit measures against is currently unenforced on this module, and two of them are unenforceable as the repository stands:

> **`memox-api` has never been verified by CI, and its test suite cannot be run on the developer's machine.**

Everything in §2 follows from that one sentence. Fix it and the rest becomes ordinary work; leave it and any convention adopted in §3 or §4 decays silently, exactly the way `integration_test/` decayed for seventy PRs (`CLAUDE.md`, "A new feature means re-running the integration suite").

Counts: **2 blockers · 6 required corrections · 7 improvements · 7 candidate findings checked and dismissed.**

---

## 2. Blockers — nothing verifies this module

### B1 · `memox-api` has no CI at all

```bash
grep -rniE "maven|mvnw" .github/workflows/*.yml
```

returns nothing. The four workflows are `ci.yml`, `ci-full.yml`, `ci-device.yml` and `build-apk.yml`; the `actions/setup-java@v6` steps in `ci-device.yml:40` and `build-apk.yml:73` exist for **Gradle and the Android toolchain**, not for Maven. No workflow compiles this module, runs its tests, or reads its coverage.

The consequence is not theoretical. `docs/superpowers/plans/2026-09-06-memox-api-phase-0-foundation.md` and the Phase 1 plan both record their tasks as verified by `./mvnw.cmd test` — a local command, run once, by whoever was at the keyboard. Nothing has re-run it since. This module's green status is a memory, not a measurement.

**Severity: blocker.** Not because a rule says so, but because every other finding in this document is un-fixable-in-a-durable-way until a gate exists to hold the fix in place.

### B2 · The test suite cannot run on this machine — 21 of 32 tests error

```text
[ERROR] Tests run: 32, Failures: 0, Errors: 21, Skipped: 0
```

Every one of the 21 is the same failure: `Failed to load ApplicationContext` for a context importing `PostgresTestcontainersConfiguration`. That class asks Testcontainers for a `postgres:16-alpine` container (`src/test/java/com/memox/support/PostgresTestcontainersConfiguration.java:13`), and **Docker is not installed**:

- Git Bash: `docker: command not found`
- PowerShell: `Get-Command docker` → `NOT INSTALLED`

A local PostgreSQL 17 **is** running (`Test-NetConnection localhost -Port 5432` → `True`, service `postgresql-x64-17` Running), so the module has a usable database; it simply cannot reach the one the tests insist on.

The 11 tests that do pass are the ones needing no database context: `PageHelperTest`, `DeckEnumTest`, `ApiHealthControllerTest`, `CardControllerWebMvcTest`, `LayerArchitectureTest`. **Every business rule in the module is tested only through a container** — see I6.

**Severity: blocker.** TDD is a stated global constraint of both existing memox-api plans ("Every production behavior is introduced by a failing test"). It is currently impossible to satisfy on this machine.

---

## 3. Required corrections — a stated rule is broken

### R1 · No static-analysis gate; coverage is measured but never enforced

`springboot-coding-convention.md` §11 requires "Checkstyle/SpotBugs/PMD trong CI". `pom.xml` declares four plugins: `maven-enforcer-plugin`, `spring-boot-maven-plugin`, `maven-compiler-plugin`, `jacoco-maven-plugin`. None of the three named analysers is present.

JaCoCo is configured with exactly two goals — `prepare-agent` (`pom.xml:257`) and `report` (`pom.xml:264`). **There is no `check` goal**, so no coverage threshold exists and no build can fail on coverage. The module produces a coverage report that nothing reads.

### R2 · `DeckNotFoundException` accepts the deck id and throws it away

```java
public DeckNotFoundException(String deckId) {   // deck/domain/DeckNotFoundException.java:13
    super(ApiErrorCode.DECK_NOT_FOUND);          //                                      :14
}
```

`deckId` is never stored, never logged, never reaches the `ProblemDetail`. `MemoxException`'s message is `errorCode.name()`, so the exception carries the string `"DECK_NOT_FOUND"` and nothing else. When a 404 is investigated in production, the id that was not found is not recoverable from the log line.

This also violates `universal-coding-contract.md` — "Throw specific exceptions with precise messages that explain the violated rule" — and the parameter is dead weight that reads like it is doing something.

### R3 · The committed OpenAPI artifact the spec promises does not exist

`docs/superpowers/specs/2026-09-06-memox-api-design.md` states: "A canonical exported OpenAPI JSON file is committed and diffed in CI so code changes cannot silently change the API contract."

There is no such file (`find . -iname '*openapi*'` returns only Java sources and build output). `OpenApiContractTest` asserts that four paths exist and that `info.title` is `"MemoX API"` (`src/test/java/com/memox/contract/OpenApiContractTest.java:22-29`). That is a smoke test, not a contract diff: renaming a field, changing a status code, dropping a required property, or altering a response schema all pass it unchanged.

**This finding invalidates a step in an unmerged plan.** `docs/superpowers/plans/2026-09-09-memox-api-phase-2-library-writes.md` Task 15 Step 4 says "assert … against the committed snapshot". There is no snapshot to assert against; that step must be rewritten to *create* one first.

### R4 · The paging contract diverges from the skill's shared contract

`pagination-contract.md` fixes four names and their shapes. The module matches one of them.

| Contract requires | `memox-api` has |
|---|---|
| `PageQuery<TSort extends Enum<TSort>>` with `page`, `size`, `search`, `List<SortSpec<TSort>>` | `PageQuery` — **not generic** — with `limit`, `offset` only (`common/pagination/PageQuery.java`) |
| `SortSpec<TSort>` | absent |
| `SortDirection` | absent |
| `PagingResponse<T>` with `page`, `size` | `PagingResponse<T>` with `limit`, `offset` (`common/pagination/PagingResponse.java`) |

`PagingResponse<T>` keeps the right name and the right `T`; its page-position fields disagree.

**This one is not a simple defect, and §7 does not resolve it here.** The module's own design spec explicitly chose limit/offset — "Paginated responses state their `limit`, `offset`, `totalItems`, `totalPages`, navigation flags, ordering and stable tie-breaker explicitly." A repo-level written decision and a cross-project skill standard disagree. Changing it is a breaking change to a published contract and rewrites the paging half of the Phase 2 plan; not changing it means this module permanently diverges from every other backend the owner runs.

### R5 · The feature package layout is a third structure

`anti-patterns.md` names this directly: "Creating a third package structure when the skill already supports feature-oriented and layered monolith only."

| Skill's feature-oriented layout | `memox-api` |
|---|---|
| `<feature>/controller/` | `<feature>/api/` |
| `<feature>/dto/request/`, `<feature>/dto/response/` | also `<feature>/api/` — requests, responses and the controller share one package |
| `<feature>/entity/`, `<feature>/enums/`, `<feature>/exception/` | all three collapsed into `<feature>/domain/` |
| `<feature>/mapper/` (MyBatis) | `<feature>/persistence/` |
| `<feature>/service/impl/` | `<feature>/service/` with concrete classes |

The `persistence/` name is **defensible on its own** — `spring-boot-mybatis.md` permits "mapper/ or the repository-equivalent package already used by the repo". The rest is a genuine third shape. Whether that matters is §7's second open decision: `LayerArchitectureTest` already enforces the *directions* between these packages, which is the property that actually protects the design; the names are consistency with the owner's other projects.

### R6 · The mandated shared libraries are absent

`springboot-coding-convention.md` §0 lists five required dependencies: `commons-lang3`, `commons-collections4`, `commons-io`, `commons-csv`, `commons-validator`. `pom.xml` declares none.

**Reported with a caveat, because the rubric argues against itself here.** `code-quality.md` — which SKILL.md designates as the winner on any conflict — says "Do not create extension points for imagined future requirements." This module does no file I/O, no CSV, no collection gymnastics; adding four of the five libraries today would add unused dependencies and their CVE surface. The honest reading is that `commons-lang3` earns its place the moment a null-safe string predicate is written (`§7` of the checklist would then demand `StringUtils` over `.trim()`/`.isBlank()`, and `DeckService.normalizeName` at `deck/service/DeckService.java:126` is already that code), and the other four wait for a consumer.

---

## 4. Improvements — correct today, will cost later

### I1 · Services write no logs at all

`code-quality.md`: "In layered Spring code, `ServiceImpl` is the preferred place for business-relevant logs because it owns orchestration and transaction context."

`DeckService` (129 lines) and `CardService` (63 lines) contain no logger and no log statement. Every conflict path — depth exceeded, parent holds cards, root cannot hold cards, scheduler invalid — throws silently. `ApiExceptionHandler` logs only `DataIntegrityViolationException` at WARN (`common/error/ApiExceptionHandler.java:67`) and unexpected exceptions at ERROR (`:73`); a business conflict produces no server-side record at all.

Adding logs here must respect the repo's hard rule: **never log card content, deck names, notes or tag names at any level** (`CLAUDE.md`; BR-51, BR-52, BR-267). Ids, counts and error codes only.

### I2 · `DeckMapperTest` proves its point through reflection

```java
final var method = DeckMapper.class.getMethod("readSchemaVersion");   // :20
assertThat(method.invoke(deckMapper)).isEqualTo("v1");
```

`readSchemaVersion()` is a public no-arg method on an injected bean; `deckMapper.readSchemaVersion()` is the same assertion with compile-time checking. The reflection form silently survives a rename, which is precisely the failure the test exists to catch.

### I3 · `readSchemaVersion` is production code with only a test caller

`DeckMapper.readSchemaVersion()` (`deck/persistence/DeckMapper.java:16`, XML at `mybatis/deck_mapper.xml:23`) is referenced from exactly one place: `DeckMapperTest:20`. It also reads `api_metadata` — a table owned by no feature — from the **deck** mapper, which puts infrastructure metadata behind a feature boundary. Either move it to a `common` health/metadata mapper or delete it once a real deck query covers the smoke path.

### I4 · Two exceptions carry empty Javadoc blocks

`deck/domain/DeckConflictException.java:8-10` and `deck/domain/DeckNotFoundException.java:8-10` each hold an IDE-generated `/** */` with no content above `serialVersionUID`. Noise; delete the block, keep the field.

### I5 · `this.` is used in one file and nowhere else

`card/api/CardController.java:71` (and its sibling lines) qualifies fields with `this.`; `DeckController`, `DeckService` and `CardService` do not. Cosmetic, but it is the kind of drift a formatter or Checkstyle rule (R1) settles permanently rather than by review.

### I6 · Every business rule is tested only at container level

The module has two plain unit tests (`PageHelperTest`, `DeckEnumTest`) and one sliced web test (`CardControllerWebMvcTest`). Every rule in `DeckService` — depth limit, content-type locking, root-cannot-hold-cards, scheduler validity — is exercised only through `DeckControllerTest` and `CardControllerTest`, both `@SpringBootTest` subclasses of `PostgresIntegrationTest`.

`review-checklist.md` §8 asks for "the smallest useful test". The rules that need the database *at the moment of writing* genuinely belong in an integration test — `CLAUDE.md`'s own reasoning about transaction-bound checks applies here. But `depthOf`, name normalisation and the scheduler-state guard are pure functions over data already loaded, and they are why a developer without Docker cannot test a business rule at all.

### I7 · `DeckService.depthOf` walks the tree one query at a time inside the write transaction

`deck/service/DeckService.java:113-124` loops up to `MAX_TREE_DEPTH` times, issuing a separate `findActiveDeckById` per level, inside `createSubDeck`'s transaction. The Drift side answers the same question in one recursive CTE (`deckDepthProbe`).

**Already scheduled**: `docs/superpowers/plans/2026-09-09-memox-api-phase-2-library-writes.md` Task 4 replaces it. Listed here for completeness, not as new work.

---

## 5. What already meets the standard

Stated explicitly, so a later reader does not "fix" something that is correct:

- **Layering is enforced, not just described.** `LayerArchitectureTest` runs three ArchUnit rules keeping `api` out of `persistence`, `service` out of `api`, and `persistence` out of `api`.
- **All SQL is in `*_mapper.xml`.** No `@Select`/`@Insert`/`@Update`/`@Delete` annotation exists anywhere (`grep -rn "@Select\|@Insert\|@Update\|@Delete" src/main` → empty). This is the MyBatis branch's central rule and it holds.
- **One top-level type per file**, throughout. No inner DTOs, no nested enums.
- **Errors are centralised and internationalised.** One `@RestControllerAdvice`, RFC 9457 `ProblemDetail`, `code` as a stable machine value, `requestId` propagated from MDC, and every message resolved from `messages.properties` / `messages_vi.properties`. No user-facing text is a Java literal.
- **Validation messages are bundle keys**, not strings: `@NotBlank(message = "{validation.required}")` throughout the request records.
- **Enums are enums.** `DeckContentType` and `SchedulerType` implement `PersistableEnum` with one shared `AbstractStringValueEnumTypeHandler`; no finite state is a loose string.
- **The clock is injected.** `TimeConfiguration` provides `Clock`; no service calls `Instant.now()` without it.
- **Status codes are deliberate.** `201` with a `Location` for both create paths, `409` for conflicts, `404` for not-found, `400` for validation.
- **Lombok is used the way the standard asks** — `@RequiredArgsConstructor` on beans, `@UtilityClass` on constant holders (`PaginationConstants`, `ValidationPatterns`, `DeckPositionScope`), `@Slf4j` on the one class that logs.
- **`@Transactional` sits on services only**, never on a controller, and read paths carry `readOnly = true`.
- **Flyway owns the schema**, migrations are numbered and immutable, and `FlywayMigrationTest` asserts the full table surface.
- **A concurrency test exists** for sibling-position assignment (`DeckConcurrencyTest`) — the one race in the module worth proving.

---

## 6. Checked and dismissed

Seven findings that a checklist pass would report and that reading the code refutes. Recorded so the next audit does not re-raise them.

| Candidate | Why it is not a finding |
|---|---|
| `catch (Exception)` in `ApiExceptionHandler:71` | `anti-patterns.md` scopes this to the **service** layer ("Catching `Exception` broadly and translating everything to one vague error"). In a `@RestControllerAdvice` a typed fallback is the intended safety net, and this one logs the class name at ERROR before returning `INTERNAL_SERVER_ERROR`. |
| No `Service` interface + `ServiceImpl` | `springboot-coding-convention.md` §2 requires it; `code-quality.md` forbids it for a single implementation. `SKILL.md`'s own canonical note says `code-quality.md` wins on conflict, and each service has exactly one implementation with no sign of variation. **Current code is correct.** Reopened as an owner's choice only in §7. |
| `persistence/` should be `mapper/` | `spring-boot-mybatis.md` permits "the repository-equivalent package already used by the repo". Folded into R5 as naming consistency, not as a rule break. |
| Missing JavaDoc on controllers and public service methods | `review-checklist.md` §7 is scoped "Apply this section only for Lumos backend JPA work". This is neither Lumos nor JPA. |
| Custom exceptions must declare `serialVersionUID` | Same §7 scoping — and they declare it anyway. |
| `LOWER(#{front})` is not the Dart fold | Verified equal. `lib/core/text/search_fold.dart:22` defines `foldForSearch(raw) => raw.trim().toLowerCase()`; `CardService.normalizeRequired` trims before binding, so `LOWER()` on a UTF-8 database is the same transformation. A pinning test is worth adding; a defect is not. |
| `ValidationPatterns.UUID` shadows `java.util.UUID` | Always referenced qualified as `ValidationPatterns.UUID`. No shadowing occurs. |

---

## 7. The two decisions this audit does not make

Both are scope choices with real costs on either side, and both change what the Phase 2 plan has to say.

**D1 — the paging contract (R4).** Adopt `PageQuery<TSort>` / `SortSpec<TSort>` / `page`+`size`, breaking the published contract and rewriting the paging half of the Phase 2 plan? Or keep `limit`/`offset` as `2026-09-06-memox-api-design.md` decided, and accept permanent divergence from the owner's cross-project standard? A middle path exists — keep the wire contract, add `SortSpec<TSort>` and a per-feature sort enum for the sorting half that does not exist yet — and it is the only option that costs nothing already built.

**D2 — the package layout (R5).** Rename `api/` → `controller/` + `dto/{request,response}/` and split `domain/` → `entity/` + `enums/` + `exception/`? The directions between these packages are already enforced by `LayerArchitectureTest`, so this buys familiarity across the owner's projects, not safety. It is a wide, mechanical diff that touches every import in the module and every file path in the Phase 2 plan.

Neither is urgent. **B1 and B2 are**, and they are the only findings here whose cost grows every day they are left.

---

## 8. Rubric coverage

| `review-checklist.md` section | Applies | Result |
|---|---|---|
| §2 Universal contract | yes | pass, except R2 (imprecise exception) |
| §3 Architecture and layering | yes | pass on direction; R5 on naming |
| §4 DTO and error contract | yes | pass |
| §4.2 Paging, search, sort | yes | R4 |
| §4.3 CSV helper | no | module has no CSV surface |
| §4.4 Excel helper | no | module has no Excel surface |
| §5 JPA branch | no | MyBatis project |
| §6 MyBatis branch | yes | pass — XML-only holds; see I3 |
| §6.1 Migration and integration | yes | pass |
| §6.2 Observability | yes | I1 |
| §7 Lumos JPA guard | no | not Lumos, not JPA |
| §8 Testing | yes | B2, I2, I6 |
| `spring-boot-harness` gates | yes | B1, R1 |

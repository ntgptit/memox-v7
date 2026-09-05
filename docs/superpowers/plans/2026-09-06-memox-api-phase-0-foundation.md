# MemoX API Phase 0 Foundation Implementation Plan

| | |
|---|---|
| **Status** | active |
| **Purpose** | Provide the independently testable configuration and persistence foundation required before feature API phases. |
| **Scope** | Maven dependencies, profile configuration, PostgreSQL connectivity, Flyway baseline, MyBatis XML smoke path, health and shared HTTP errors. |
| **Source of truth for** | Exact execution steps for MemoX API Phase 0. |
| **Depends on** | `docs/superpowers/specs/2026-09-06-memox-api-design.md` |
| **Updated by task** | M9 API Phase 0 |
| **Last updated** | 2026-09-06 |

> **For agentic workers:** REQUIRED SUB-SKILL: Use `superpowers:executing-plans`
> to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for
> tracking.

**Goal:** Make `memox-api` start against the configured local PostgreSQL
database, expose a versioned health probe, and prove Flyway/MyBatis run against
PostgreSQL before feature endpoints are added; H2 for the automated test suite.

**Architecture:** Configuration is environment-backed and profile-specific.
Flyway is the only schema writer. MyBatis mapper interfaces delegate to XML SQL
and are exercised through an integration test; controllers return RFC 9457
Problem Details via one advice.

**Tech Stack:** Java 17, Spring Boot 3.5, PostgreSQL runtime, H2 test runtime,
Flyway, MyBatis, Spring MVC, Spring Boot Actuator, JUnit 5.

**Spec:** `docs/superpowers/specs/2026-09-06-memox-api-design.md`

## Global Constraints

- `MEMOX_DB_URL=jdbc:postgresql://localhost:5432/memox` and
  `MEMOX_DB_USERNAME=giapnt` configure the local profile; `MEMOX_DB_PASSWORD`
  is never committed.
- API paths start with `/api/v1`; all timestamps are `Instant` values rendered
  as UTC ISO-8601 strings; future resource IDs are UUID strings.
- SQL belongs only in `src/main/resources/mybatis/**/*_mapper.xml`; no MyBatis
  annotation SQL is permitted.
- Auth, synchronization and device-only effects are out of scope.
- Every production behavior is introduced by a failing test, then minimal code,
  then a passing test.

---

### Task 1: Make test and runtime profiles explicit

**Files:**
- Modify: `memox-api/pom.xml`
- Modify: `memox-api/src/main/resources/application.properties`
- Create: `memox-api/src/main/resources/application-local.properties`
- Create: `memox-api/src/test/resources/application-test.properties`
- Create: `memox-api/src/main/resources/application-prod.properties`
- Create: `memox-api/src/test/java/com/memox/config/DatabaseConfigurationTest.java`

**Interfaces:**
- Consumes: `MEMOX_DB_URL`, `MEMOX_DB_USERNAME`, `MEMOX_DB_PASSWORD`.
- Produces: an active `test` profile whose datasource is an in-memory H2
  database in PostgreSQL compatibility mode; local/prod datasource properties
  resolve only from env vars.

- [ ] **Step 1: Write the failing test**

```java
@SpringBootTest(properties = "spring.profiles.active=test")
class DatabaseConfigurationTest {
  @Autowired DataSource dataSource;

  @Test
  void connects_to_in_memory_h2() throws Exception {
    try (var connection = dataSource.getConnection()) {
      assertThat(connection.getMetaData().getDatabaseProductName()).isEqualTo("H2");
    }
  }
}
```

- [ ] **Step 2: Run the test to verify it fails**

Run: `./mvnw.cmd -Dtest=DatabaseConfigurationTest test`

Expected: FAIL because no H2 test datasource is configured.

- [ ] **Step 3: Implement the minimum configuration**

Add `com.h2database:h2` (test scope) and `spring-boot-starter-actuator` to
`pom.xml`. Configure the H2 test datasource and test-only Flyway migration
location. Keep the PostgreSQL migration unchanged because it is the runtime
schema source; the H2 equivalent exists only to support isolated tests.
Configure local and production datasource URL/username/password with required
environment placeholders; configure Flyway and MyBatis mapper locations.

- [ ] **Step 4: Run the test to verify it passes**

Run: `./mvnw.cmd -Dtest=DatabaseConfigurationTest test`

Expected: PASS and the JDBC metadata product name is `H2`.

- [ ] **Step 5: Commit**

```text
git add memox-api/pom.xml memox-api/src/main/resources memox-api/src/test/java/com/memox/config
git commit -m "feat(api): configure PostgreSQL profiles"
```

### Task 2: Establish Flyway as the schema owner

**Files:**
- Create: `memox-api/src/main/resources/db/migration/V1__create_api_metadata.sql`
- Create: `memox-api/src/test/java/com/memox/migration/FlywayMigrationTest.java`

**Interfaces:**
- Consumes: the `test` datasource from Task 1.
- Produces: `api_metadata` relation with exactly one migration-managed schema
  baseline marker, accessible to later feature migrations.

- [ ] **Step 1: Write the failing test**

```java
@SpringBootTest(properties = "spring.profiles.active=test")
class FlywayMigrationTest {
  @Autowired JdbcTemplate jdbcTemplate;

  @Test
  void migrates_the_api_metadata_table() {
    assertThat(jdbcTemplate.queryForObject(
        "SELECT COUNT(*) FROM information_schema.tables WHERE table_name = 'api_metadata'",
        Integer.class)).isEqualTo(1);
  }
}
```

- [ ] **Step 2: Run the test to verify it fails**

Run: `./mvnw.cmd -Dtest=FlywayMigrationTest test`

Expected: FAIL because no `V1__...sql` migration creates `api_metadata`.

- [ ] **Step 3: Implement the minimum migration**

Create `V1__create_api_metadata.sql` with `key VARCHAR(100) PRIMARY KEY`,
`value VARCHAR(255) NOT NULL` and `updated_at TIMESTAMPTZ NOT NULL`; do not use
Spring schema generation.

- [ ] **Step 4: Run the test to verify it passes**

Run: `./mvnw.cmd -Dtest=FlywayMigrationTest test`

Expected: PASS after Flyway applies V1 to a clean PostgreSQL container.

- [ ] **Step 5: Commit**

```text
git add memox-api/src/main/resources/db/migration memox-api/src/test/java/com/memox/migration
git commit -m "feat(api): establish Flyway baseline"
```

### Task 3: Prove the MyBatis XML seam

**Files:**
- Modify: `memox-api/src/main/java/com/memox/repository/DeckRepository.java`
- Create: `memox-api/src/main/resources/mybatis/deck_mapper.xml`
- Create: `memox-api/src/test/java/com/memox/repository/DeckRepositoryTest.java`

**Interfaces:**
- Consumes: `api_metadata` from Task 2.
- Produces: `String DeckRepository.readSchemaVersion()` backed by the XML
  statement id `readSchemaVersion`.

- [ ] **Step 1: Write the failing test**

```java
@SpringBootTest(properties = "spring.profiles.active=test")
class DeckRepositoryTest {
  @Autowired DeckRepository deckRepository;

  @Test
  void executes_the_xml_mapped_query() {
    assertThat(deckRepository.readSchemaVersion()).isEqualTo("v1");
  }
}
```

- [ ] **Step 2: Run the test to verify it fails**

Run: `./mvnw.cmd -Dtest=DeckRepositoryTest test`

Expected: FAIL because the mapper method and XML statement do not exist.

- [ ] **Step 3: Implement the minimum mapper path**

Add `String readSchemaVersion()` to `DeckRepository`.  Add an XML mapper with
namespace `com.memox.repository.DeckRepository` and statement id
`readSchemaVersion`; it selects `value` for key `schema_version`. Seed that key
in the V1 migration with value `v1`.

- [ ] **Step 4: Run the test to verify it passes**

Run: `./mvnw.cmd -Dtest=DeckRepositoryTest test`

Expected: PASS and an incorrect statement id would fail mapper binding.

- [ ] **Step 5: Commit**

```text
git add memox-api/src/main/java/com/memox/repository/DeckRepository.java memox-api/src/main/resources/mybatis memox-api/src/main/resources/db/migration memox-api/src/test/java/com/memox/repository
git commit -m "feat(api): add MyBatis XML smoke path"
```

### Task 4: Add a versioned health endpoint and common Problem Details

**Files:**
- Create: `memox-api/src/main/java/com/memox/health/ApiHealthController.java`
- Create: `memox-api/src/main/java/com/memox/health/ApiHealthResponse.java`
- Modify: `memox-api/src/main/java/com/memox/exception/MemoxException.java`
- Create: `memox-api/src/main/java/com/memox/exception/ApiExceptionHandler.java`
- Create: `memox-api/src/test/java/com/memox/health/ApiHealthControllerTest.java`
- Create: `memox-api/src/test/java/com/memox/exception/ApiExceptionHandlerTest.java`

**Interfaces:**
- Produces: `GET /api/v1/health` returning `{ "status": "UP" }` and a
  handler mapping `MemoxException` to `application/problem+json` with a stable
  `code` property.

- [ ] **Step 1: Write the failing controller tests**

```java
@WebMvcTest(ApiHealthController.class)
class ApiHealthControllerTest {
  @Autowired MockMvc mockMvc;

  @Test
  void returns_up_from_the_versioned_health_route() throws Exception {
    mockMvc.perform(get("/api/v1/health"))
        .andExpect(status().isOk())
        .andExpect(content().contentTypeCompatibleWith(MediaType.APPLICATION_JSON))
        .andExpect(jsonPath("$.status").value("UP"));
  }
}
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `./mvnw.cmd -Dtest=ApiHealthControllerTest,ApiExceptionHandlerTest test`

Expected: FAIL because no route or exception advice exists.

- [ ] **Step 3: Implement the minimum HTTP surface**

Return `ResponseEntity<ApiHealthResponse>` from the controller.  Change
`MemoxException` to require `code`, `HttpStatusCode` and diagnostic detail.
Map it in `@RestControllerAdvice` to a ProblemDetail with property `code` and
media type `application/problem+json`.

- [ ] **Step 4: Run tests to verify they pass**

Run: `./mvnw.cmd -Dtest=ApiHealthControllerTest,ApiExceptionHandlerTest test`

Expected: PASS for success and error body shape.

- [ ] **Step 5: Commit**

```text
git add memox-api/src/main/java/com/memox/health memox-api/src/main/java/com/memox/exception memox-api/src/test/java/com/memox/health memox-api/src/test/java/com/memox/exception
git commit -m "feat(api): expose health and problem details"
```

### Task 5: Verify the configured local server safely

**Files:**
- Create: `memox-api/compose.yaml`
- Create: `memox-api/.env.example`
- Modify: `memox-api/.gitignore`
- Create: `memox-api/README.md`

**Interfaces:**
- Consumes: the Phase 0 configuration and migrations.
- Produces: a reproducible local PostgreSQL command and documented environment
  setup that never stores the actual password.

- [ ] **Step 1: Write the failing startup assertion**

Create `LocalProfileConfigurationTest` that uses explicit test properties and
asserts `spring.datasource.url` is never hardcoded in `application.properties`.

- [ ] **Step 2: Run it to verify it fails**

Run: `./mvnw.cmd -Dtest=LocalProfileConfigurationTest test`

Expected: FAIL until environment-backed local configuration exists.

- [ ] **Step 3: Implement compose and docs**

Compose creates only a `postgres:16-alpine` database named `memox` on port
`5432`. `.env.example` names the three variables with an empty password value.
`.gitignore` ignores `.env`. README documents setting the password in the shell,
starting Compose and running `./mvnw.cmd -Dspring-boot.run.profiles=local spring-boot:run`.

- [ ] **Step 4: Run the final Phase 0 verification**

Run: `./mvnw.cmd test`

Expected: all unit, MVC, Flyway and H2 mapper tests pass. With the three
environment variables set, run
`./mvnw.cmd -Dspring-boot.run.profiles=local spring-boot:run` and request
`GET /api/v1/health`.

- [ ] **Step 5: Commit**

```text
git add memox-api/compose.yaml memox-api/.env.example memox-api/.gitignore memox-api/README.md memox-api/src/test/java/com/memox/config
git commit -m "docs(api): document local PostgreSQL startup"
```

## Self-review

- Spec coverage: Phase 0 configuration, PostgreSQL, Flyway, MyBatis, health,
  shared errors and verification each map to Tasks 1–5. Feature API modules are
  intentionally deferred to their own plans after this deployable foundation.
- Placeholder scan: no task uses a deferred implementation marker; every task
  names files, interfaces, a failing behavior, a command and pass condition.
- Type consistency: Task 3 defines `DeckRepository.readSchemaVersion()` before
  it is consumed by its test. Task 4 defines the health response and exception
  seam before its MVC tests consume them.

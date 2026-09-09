# memox-api

Spring Boot 3.5 / Java 17 backend for MemoX. PostgreSQL, Flyway, MyBatis with all SQL in
`src/main/resources/mybatis/*_mapper.xml`.

Design and phase plan: `../docs/superpowers/specs/2026-09-06-memox-api-design.md`.
Standards audit: `../docs/reviews/memox-api-spring-standards-audit.md`.

## The development database

`compose.yaml` provides the database the application runs against under the `local` profile.

```bash
cp .env.example .env          # then set MEMOX_DB_PASSWORD
docker compose up -d
./mvnw -Dspring-boot.run.profiles=local spring-boot:run
```

**It will clash with a host PostgreSQL on 5432.** This machine runs one as the Windows service
`postgresql-x64-17`. Run one or the other: either stop that service, or set `MEMOX_DB_PORT` to a free
port in `.env` **and** change the port inside `MEMOX_DB_URL` to match. The two are not linked, and a
mismatch surfaces as `connection refused` rather than as a configuration error.

`docker compose down` keeps the data; `down -v` deletes it.

The second service, `db-test`, is opt-in (`docker compose --profile test up -d`) and is **not needed
when Docker is available** — Testcontainers provisions its own database per run. It exists for
watching the database between tests, or reproducing the CI `local` matrix leg exactly.

## Running the tests

The suite needs a real PostgreSQL — every business rule in this module is enforced inside a
transaction, so an in-memory substitute would prove nothing. There are two ways to give it one.

### With Docker (the default, and what CI uses)

```bash
./mvnw -B verify
```

Testcontainers starts `postgres:16-alpine`, throws it away afterwards, and nothing needs setting up.

### Without Docker, against a local PostgreSQL

One-time setup. **Use a disposable database — the suite cleans and truncates it on every run**, and
it refuses to touch any database whose name does not end in `_test`:

```bash
"/c/Program Files/PostgreSQL/17/bin/psql.exe" -U giapnt -h localhost -d postgres -c "CREATE DATABASE memox_test ENCODING 'UTF8'"
```

Then every run:

```bash
MEMOX_TEST_DATABASE=local MEMOX_TEST_DB_PASSWORD=<your local password> ./mvnw -B verify
```

`MEMOX_TEST_DB_URL` and `MEMOX_TEST_DB_USERNAME` default to
`jdbc:postgresql://localhost:5432/memox_test` and `giapnt`; override them if yours differ.

**Never point this at `memox`.** That is the application's own database, one character away, on the
same host and port. The `_test` suffix rule is the only thing standing between the two, and it is
enforced in code — `DisposableTestDatabase` — not by convention.

### Two commands, two questions

- `./mvnw -B test` — the inner loop. Compiles, runs Surefire. Checkstyle still runs (it binds to
  `validate`, before `test`), so a new file must satisfy the ruleset. `-Dcheckstyle.skip` is never
  the fix.
- `./mvnw -B verify` — the pre-push gate. Adds PMD, SpotBugs, the JaCoCo threshold and the OpenAPI
  snapshot check. This is what CI runs; run it before pushing.

### When it fails at startup

| Message | Cause |
|---|---|
| `fe_sendauth: no password supplied` | `MEMOX_TEST_DB_PASSWORD` is not set |
| `database "memox_test" does not exist` | The one-time `CREATE DATABASE` above was skipped |
| `Refusing to modify database 'memox'` | `MEMOX_TEST_DB_URL` points at the application database |
| `Could not find a valid Docker environment` | No Docker, and `MEMOX_TEST_DATABASE=local` was not set |

## Why the two backends must not drift

CI runs the container backend; a machine without Docker runs the local one. They are only
equivalent while both start from an empty schema, so the local backend runs `clean()` before
`migrate()` on the first Spring context of each JVM — a long-lived database that keeps the previous
run's rows is the one way the two stop being the same test.

Encoding is pinned to UTF-8 on both. Collation deliberately is not: PostgreSQL's `lower()` follows
LC_CTYPE, and pinning it to `C` would fold ASCII only — `LOWER('ÁNH')` would come back unchanged and
the card mapper's fold would silently stop matching the Flutter app's. Deterministic ordering is
taken per statement with `COLLATE "C"` instead.

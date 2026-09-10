# AGENTS.md

**You are in `memox-api`, the Spring Boot backend. The repository root's
[`CLAUDE.md`](../CLAUDE.md) is the Flutter client's contract, and most of it does
not apply in this directory.** That file opens with "Flutter application" and
its non-negotiables are Dart ones — `domain/`/`data/`/`presentation/` layering,
Drift, `widgets/` buckets, design tokens, ARB strings, golden files. None of them
name Java, and none of them govern a class under `src/main/java`.

This file exists to say which half still binds you and where this module's own
contract lives. It restates neither: `../docs/document-conventions.md` says one
fact lives in exactly one place, and a second copy of the build instructions here
would be the copy that goes stale.

## What still binds you from the root contract

| Still applies | Does not apply |
|---|---|
| Conventional Commits, scope = feature name; small single-purpose PRs | The Flutter layering and folder/suffix rules |
| The merge order: sync with `main`, confirm `MERGED`, **then** delete the branch | Drift, `.drift` files, `schemaVersion`, migration snapshots |
| Never force-push a branch a cloud session is on | Design tokens, ARB strings, `Mx*` widgets, Design System V1 freeze |
| `docs/` conventions for anything you write under `../docs/` | Goldens, the screen gallery, the 393×852 rule |
| **Docs outrank code and tests** — a `BR-xx` beats an agreeing test | `integration_test/` on an emulator, `dod_check.sh` |
| Prose without MUST/SHOULD/MAY is explanation, not a rule | The 22-phase checklist and `docs/wbs.md` phase ledger |

## The business rules are shared, and they are not in this directory

`src/main/java` cites **38 distinct `BR-xx` identifiers** — BR-51, BR-55, BR-90,
BR-151, BR-163, BR-267 and more. They are defined in
[`../docs/business-rules.md`](../docs/business-rules.md) and nowhere else. This
module is a second implementation of the same rules the Flutter client
implements, not a separate product with its own logic.

So when a rule looks wrong here, the fix is not in `service/`. Read the BR first;
if the BR is what is wrong, changing it is a documents task, and
`docs/business-rules.md` is frozen for MVP.

## `.claude/skills/` does not cover this module

The thirteen skills under `../.claude/skills/` are the Flutter phase router —
`flutter-workflow` routes among them, and every one of them is about the Dart
app. There is no skill for this module, and `flutter-workflow` will not send you
anywhere useful from here.

The same goes for the repository's `code-verification-guard`: its `memox-v7`
ruleset scopes `lib/**/*.dart`, so it reads nothing in this directory. Do not
read a green guard run as having checked this module.

## What actually holds this module

Layer boundaries are enforced, not described, by
`src/test/java/com/memox/architecture/LayerArchitectureTest.java` — an ArchUnit
suite. It is the local answer to `check_architecture.sh`, and it is stricter than
a convention because it fails the build:

- `transportDoesNotReachPersistence` — `..controller..` and `..dto..` may not
  reach `..persistence..`
- `servicesDoNotReachTransport` / `persistenceDoesNotReachTransport` — nothing
  below transport may reach back up into it
- `entitiesDependOnNoOuterLayer` — `..entity..` depends on no outer layer
- `everyClassLivesInTheDeclaredLayout` — a feature class may only sit in
  `controller`, `dto.request`, `dto.response`, `entity`, `enums`, `exception`,
  `persistence` or `service`. `com.memox.tag.domain` is not a package you may
  invent.
- `commonKnowsNoFeature` — `com.memox.common..` may not depend on a feature
- `featuresDoNotReachEachOthersInternals` — a feature may call another feature's
  `..service..` and touch the types on that signature; what stays forbidden for
  everyone is another feature's `..persistence..`. A controller, a DTO or a
  mapper naming another feature's type is refused outright
- `sqlLivesOnlyInMapperXml` — no `@Select`/`@Insert`/`@Update`/`@Delete` on a
  persistence method; SQL lives in `src/main/resources/mybatis/*_mapper.xml`.
  This is the same decision the client makes when it puts SQL in `.drift` files
  rather than in Dart: SQL belongs somewhere a tool can read it.

`everyGuardedPackageStillExists` fails when a package named in those rules stops
matching any class, so a rename cannot quietly leave the assertions guarding an
empty set.

## The gate

```bash
./mvnw -B -ntp verify
```

CI runs it as the job **`memox-api · verify`**, on a `needs_memox_api` classify
output, across a two-value matrix — `testcontainers` and `local`. Both legs run
every time on purpose; the README explains why they must not drift.

## References

Read only what the task touches:

- [`README.md`](README.md) — the development database, running the tests, how the
  SQL is laid out, and why the two test backends must not drift
- [`../docs/business-rules.md`](../docs/business-rules.md) — the `BR-xx` this
  module implements
- [`../docs/superpowers/specs/2026-09-06-memox-api-design.md`](../docs/superpowers/specs/2026-09-06-memox-api-design.md) — design and phase plan
- [`../docs/reviews/memox-api-spring-standards-audit.md`](../docs/reviews/memox-api-spring-standards-audit.md) — standards audit
- `src/main/resources/db/migration/` — Flyway, `V1`…`V5`, immutable once merged

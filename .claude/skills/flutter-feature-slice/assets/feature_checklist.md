# Feature: <name>

WBS task: `T<x.y>` · Use cases: `UC-xx` · Business rules: `BR-xx`

## Pre-flight
- [ ] Use case approved with main / alternative / error flows
- [ ] Business rules and validation messages written
- [ ] Design available, or agreement to use existing components only
- [ ] State matrix decided (initial / loading / loaded / empty / error / refreshing / submitting)
- [ ] API contract in `docs/api-spec.md`
- [ ] Data model and migration need known
- [ ] Acceptance criteria written and externally checkable
- [ ] Dependencies on other features identified and available

## Layout (AD-12)
- [ ] `domain/{entities,repositories,models,usecases,failures}/`
- [ ] `data/{repositories,mappers,datasources,models}/`
- [ ] `presentation/{screens,controllers,states,widgets,providers}/`
- [ ] Every file carries the suffix its folder admits — the folder does not
      replace the suffix
- [ ] No controller reads a repository; the dependency direction is
      `presentation → use case → contract ← impl`

## Domain
- [ ] Entity / value objects, immutable, value equality
- [ ] Entity state as enum or sealed class
- [ ] Repository contract, shaped by what presentation needs
- [ ] One use case per interaction, taking the contract
- [ ] Input validation lives in the use case — not also in the controller, and
      not also in the repository
- [ ] Any rule needing the data *as it stands at write time* stays in the
      repository, inside its transaction
- [ ] Failure reasons are enums in `domain/failures/`, never sentences in
      `Failure.message`
- [ ] No Flutter / Dio / Drift / json_annotation imports

## Data
- [ ] DTO (`*_model.dart`)
- [ ] Remote data source
- [ ] Local data source / DAO
- [ ] Mapper DTO ↔ entity, handling nulls and unknown enum values
- [ ] Repository implementation
- [ ] Exceptions mapped to `Failure` at the repository boundary
- [ ] Cache / sync policy applied per `docs/architecture.md`
- [ ] Migration written and tested if the schema changed

## Presentation
- [ ] State class, immutable, data separate from task status
- [ ] Controller — no `BuildContext`, `ref.mounted` after awaits, duplicate submits guarded
- [ ] Screen
- [ ] Sections split into separate widget classes
- [ ] Route registered by name in `route_paths.dart`
- [ ] Only tokens and existing components used
- [ ] Loading state
- [ ] Empty state
- [ ] Error state with retry
- [ ] Success / loaded state
- [ ] Side effects via `ref.listen`, consumed so they do not re-fire
- [ ] All user-visible strings in ARB

## Cross-cutting
- [ ] Light mode
- [ ] Dark mode
- [ ] 320px-wide screen — no overflow
- [ ] 2.0× text scale — no overflow
- [ ] Keyboard open — focused field and submit button reachable
- [ ] Landscape
- [ ] Semantic labels on icon-only controls
- [ ] Touch targets ≥ 48×48
- [ ] No information conveyed by colour alone
- [ ] Nothing sensitive logged

## Tests
- [ ] Domain logic and validation, including rule violations
- [ ] Repository, with failure paths and cache fallback
- [ ] Mapper, including null and unknown-enum cases
- [ ] Controller: initial, loading→loaded, loading→error, refresh, submit ok, submit fail, duplicate submit
- [ ] Widget: loaded, empty, error
- [ ] Integration: main flow
- [ ] Golden: any new shared component, light and dark

## Done
- [ ] `dod_check.sh` passes
- [ ] `python code-verification-guard-v2/guard/run.py check --project . --ruleset memox-v7` clean
- [ ] `docs/wbs.md` updated in this commit
- [ ] Affected docs updated in this commit
- [ ] Descoped items recorded with reasons
- [ ] Reviewed against the full Definition of Done
- [ ] Conventional commit, scoped to this feature

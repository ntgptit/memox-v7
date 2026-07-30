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

## Layout (AD-12, AD-13)
- [ ] `domain/{entities,repositories,models,usecases,failures}/`
- [ ] `data/{repositories,mappers,datasources,models}/`
- [ ] `presentation/{screens,controllers,states,widgets,providers}/`
- [ ] `di/` — one provider per contract the feature needs, declared as the
      **domain type**, bound in `app/di/repository_bindings.dart`
- [ ] Every file carries the suffix its folder admits — the folder does not
      replace the suffix
- [ ] No controller reads a repository; the dependency direction is
      `presentation → use case → contract ← impl`
- [ ] **No file under `lib/features/` imports `lib/app/`.** A constant both the
      router and a screen speak goes in `core/`, not upward

## Domain
- [ ] Entity / value objects, immutable, value equality
- [ ] Entity state as enum or sealed class
- [ ] Repository contract, shaped by what presentation needs
- [ ] One use case per interaction, taking the contract. **One interaction is not
      one statement** — a screen needing two facts at once gets one read, not two
      use cases composed in a controller
- [ ] Every read a screen renders together comes from **one** statement, so the
      screen cannot show two snapshots. A count with an expiry carries the expiry
- [ ] Input validation lives in a **value object** whose constructor is private —
      not in the controller, not in the repository, and not re-derived in the
      widget to decide which field to mark
- [ ] `ValidationFailure` carries `Set<Enum> problems`, so one attempt reports
      every wrong field. No `Map<String, String>`: the value would be copy the UI
      must not render, which is what makes presentation re-derive the rule
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
- [ ] Controller — no `BuildContext`, `ref.mounted` after awaits, duplicate submits
      guarded. It owns steps 2, 3 and 8 of the nine-step submit flow and no others
- [ ] Nothing reads the wall clock inside the feature — `clockProvider` is passed
      in, and `lib/features/` contains no `DateTime.now()`
- [ ] Any timer is armed from the data, cancelled on dispose, and never duplicated
      by a rebuild
- [ ] Screen
- [ ] Sections split into separate widget classes
- [ ] Route path in `app/router/route_paths.dart`; its **name** and path
      parameters in `core/navigation/route_names.dart`
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
- [ ] **Every new guard or architecture test fault-injected**: create the
      violation, watch it fail, revert, watch it pass. Record what was injected
- [ ] Every guard prints what it scanned and fails on zero — a rule that inspects
      nothing passes, and reads as coverage

## Done
- [ ] `dod_check.sh` passes
- [ ] CI green on the PR — the same gates, plus the web build and the
      generated-code check
- [ ] `python code-verification-guard-v2/guard/run.py check --project . --ruleset memox-v7` clean
- [ ] `docs/wbs.md` updated in this commit
- [ ] Affected docs updated in this commit
- [ ] Descoped items recorded with reasons
- [ ] Reviewed against the full Definition of Done
- [ ] Conventional commit, scoped to this feature

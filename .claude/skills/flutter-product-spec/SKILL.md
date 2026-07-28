---
name: flutter-product-spec
description: Turns a vague product idea into the written artifacts that all later Flutter work depends on — problem statement, target users, platform and offline/online decision, MVP scope with must/should/nice classification, use cases with full flows, business rules, validation rules, entity state machines, and the WBS. Use this skill whenever the request involves deciding what to build rather than how — "what should the app do", "define the MVP", "write the use cases", "plan the features", "break this into tasks", "create the WBS" — and always before any code is written for a new feature or a new app. Also use it when a coding task turns out to have unsettled business rules, which is the usual reason a feature gets rebuilt.
---

# Product specification and planning

Covers checklist Phases 0 and 1. Output is documents in `docs/`, not code.

The point of this phase is not paperwork. It is that every ambiguity you leave
here becomes a rewrite later, and the rewrite costs 10–50× what settling the
question now costs. A use case with an unspecified error flow becomes a screen
with no error state; an entity with an unspecified state machine becomes a pile
of booleans that eventually contradict each other.

## Work with what the user actually knows

Most people arrive with a clear idea of the happy path and a fuzzy idea of
everything else. Do not hand them a blank template and ask them to fill it in —
draft it from what they have said, mark what you inferred, and ask about the
gaps that actually change the build.

The questions that change the build, roughly in order of leverage:

1. **Offline-first, online-first, or hybrid?** This decides whether Drift is the
   source of truth or a cache, whether you need sync and conflict resolution, and
   what every repository looks like. Getting this wrong is the most expensive
   mistake available in this phase.
2. **Which platforms, for real?** "Maybe web later" and "web at launch" produce
   different plugin choices and different responsive work.
3. **Is there auth, and are there roles?** Auth reaches into the router (guards),
   the network layer (token refresh), storage (secure storage) and the entire
   test setup.
4. **What data is sensitive?** Decides secure storage, database encryption,
   logging redaction, and what may appear in analytics.
5. **What is genuinely in the MVP?** Everything else is a distraction, and the
   most common failure is an MVP that quietly contains twelve features.

Ask these in a batch, not one at a time. Everything else you can draft and let
them correct — reacting to a draft is far easier than answering an open question.

## Documents to produce

Write into `docs/`. Templates are in `assets/`.

| File | Contains | Template |
|---|---|---|
| `docs/product.md` | Problem, users, core value, platforms, online/offline, auth, sensitive data | `assets/product_template.md` |
| `docs/mvp.md` | Feature list classified must/should/nice/out, with completion conditions | `assets/product_template.md` |
| `docs/use-cases.md` | One entry per use case, full flows | `assets/use_case_template.md` |
| `docs/business-rules.md` | Rules, validation rules, entity states, edge cases | `assets/business_rules_template.md` |
| `docs/wbs.md` | Milestones → features → tasks, the live progress ledger | `assets/wbs_template.md` |
| `docs/architecture.md` | Layering decisions and deviations, written as they are made | — |
| `docs/data-model.md` | Entities, relationships, Drift schema intent | — |
| `docs/api-spec.md` | Endpoints, request/response shapes, error format, pagination | — |
| `docs/design-system.md` | Owned by `flutter-design-system` | — |
| `docs/testing-strategy.md` | Owned by `flutter-testing` | — |
| `docs/release-checklist.md` | Owned by `flutter-ship` | — |

Do not create empty placeholder files for the last four before the phase that
owns them — an empty document reads as "considered and found to need nothing",
which is worse than an absent one. `docs/README.md` should list what exists and
what is deliberately not written yet.

## Use cases

Every use case needs all seven parts. The three that get skipped and shouldn't:

- **Alternative flow** — what happens when the user does the reasonable-but-not-
  primary thing. This is where most missing UI states come from.
- **Error flow** — every failure the user can actually hit, and what they see.
  "Show an error" is not an error flow; say which message and what recovery is
  offered.
- **Postconditions** — what is true afterward. This is what the integration test
  asserts, and if you cannot state it, the use case is not specified.

Write the flows as numbered steps in the user's language, not in terms of
screens or widgets. Screens come later and will change; the flow should not.

## Business rules and entity states

A business rule is a statement that is true regardless of UI — "a card cannot be
reviewed more than once per day", "a deleted deck stays recoverable for 30 days".
Number them (`BR-01`) so use cases, code comments and tests can cite them.

For every entity, write the state machine explicitly: the states, the legal
transitions, and what triggers each. Then use a sealed class or enum for it in
code. The point of writing it down is that the illegal transitions become
visible — those are the bugs you would otherwise ship.

Validation rules belong next to the field they validate, with the exact message
the user sees. Vague validation ("must be valid") produces vague error text.

## WBS

Break down to tasks that are one focused sitting each. A task too large to
describe in one sentence is really several tasks, and it will be reported as
"in progress" for a long time while nobody can tell what is actually done.

Every task carries: goal, scope, output, acceptance criteria, dependencies,
required tests. Acceptance criteria must be checkable by someone who did not
write the task — "login works" is not checkable; "invalid credentials show the
inline error from BR-04 and the password field is not cleared" is.

Order tasks by dependency, and let vertical slices dominate: one feature working
end to end beats four features half-built, because only the former proves the
architecture. `docs/wbs.md` is then maintained for the life of the project as
the progress ledger — see `flutter-workflow` for the update discipline.

## When to stop

Stop when the must-have features each have use cases with all flows, the rules
they depend on are numbered and written, and the WBS covers the first milestone
in task-level detail. Later milestones can stay at feature granularity — planning
them to task level now guarantees replanning, because building the first
milestone will teach you things.

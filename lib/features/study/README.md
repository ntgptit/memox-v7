# features/study

The spaced-repetition engine (UC-05, UC-14, UC-15). The largest feature in the
app and the one where a wrong change is hardest to notice. Read
`features/deck/README.md` first for the method.

## 1 · What business problem it owns

Deciding **when** a card comes back (the scheduler) and **how** it is asked (the
mode), running a session over a fixed card set, and writing an honest history of
every turn.

It does not own the deck tree, the card content, or the generation counter —
Deck increments that. Study freezes it, compares against it, and refuses writes
that no longer match.

## 2 · Public entry points

| Kind | Where to read it |
|---|---|
| Routes | Study Home, the session screen, the entry/mode chooser |
| Contracts | `StudyRepository` (session lifecycle, deck context), plus the queue/lifecycle/trash-invalidation repositories it is split into |
| Entities | `StudySessionEntity`, `StudyAnswerEntity` |
| Strategy | `StudyScheduler` — `EightBoxScheduler`, `Sm2Scheduler` |
| Mode handlers | `StudyMode` + `studyModeHandler` — one exhaustive dispatch point |

## 3 · The two schedulers

`StudyScheduler` is pure Dart: no clock, no repository, no randomness. It returns
**a number of days**, never an instant (AD-16). Converting "N days" to a UTC
moment anchored at local midnight happens above it (BR-105).

| | `eight_box` | `sm2` |
|---|---|---|
| Actions | `forgotten`, `remembered` | `again`, `hard`, `good`, `easy` |
| Learning chain | `browse → match → guess → recall → fill` | `browse → self_assess` |
| Review modes | the four graded ones | `self_assess` only |
| State | `current_box` 1–8 | `ease_factor`, `interval_days`, `repetitions` |

**Box 8 is not graduation.** A remembered card at box 8 stays at 8 and returns in
128 days forever. "Mastered" is a derived display value, never a stored state
(BR-88).

**For `sm2`, the order inside a turn is itself the rule** (BR-18, BR-19): the
ease factor updates first — on *every* turn, including failures, floored at 1.3 —
and the interval is then multiplied by the **new** factor. `hard` moves 2.5→2.36
and a 10-day card becomes 24 days, not 25.

**Giving a scheduler the other one's action throws** rather than silently
scheduling. That is reachable in practice from a history row written before an
unlocked scheduler change (BR-164), so it is a real path, not defensive noise.

**The UI renders buttons from `supportedActions`.** Hardcoding four buttons is
wrong for every `eight_box` deck.

## 4 · Data flow, and the commit protocol

```
widget → controller → use case → StudyRepository → StudyDao → study.drift → SQLite
```

Four rules govern a turn, and each exists because the opposite shipped once:

- **Once a write starts, it commits** — even if the screen unmounts or the user
  backs out mid-write (BR-25).
- **The verdict is never drawn before the row exists.** Write, then show; never
  show, then write (BR-157).
- **After grading, the card holds on screen for a reading budget and stops
  accepting input** before the session advances (BR-158).
- **Revealing the answer is not a graded write** (BR-159). It used to double as a
  "correct" grade, silently promoting every card the learner gave up on.

## 5 · Where the business rules are

`docs/business-rules/study-mode.md` owns the mode/stage cluster; the rest is in
`business-rules.md`. Four things to get right:

### `kind` is stored, never derived (BR-76, AD-11)

`study_answers.kind` is `learning` / `scheduled` / `relearning`, decided from the
session kind and the queue row's own counter inside the write transaction — never
by diffing the schedule before and after. The comment on the code names the exact
bug: a `scheduled` turn answered `remembered` on a box-8 card leaves
`previous_box == next_box == 8`, indistinguishable from a turn that changed
nothing.

### The generation check is two commits, on purpose

A session freezes `scheduler_generation` at open. Every write compares it against
the root's current value **before** opening its own transaction. On a mismatch the
session is set to `invalidated` / `stale_generation` and **committed on its own**,
then the write is refused (BR-84).

Two commits rather than one because a rollback cannot both invalidate the session
and refuse the write — the invalidation would roll back too, leaving the session
open and still accepting turns it must not accept. Letting a stale write through
is how a Reset silently un-resets itself.

The same fact is re-checked at resume-tap, because a Reset can land between Study
Home drawing the list and the tap arriving.

### The two card sets never mix (BR-142)

`learning` takes cards with `learned_at IS NULL`; `reviewing` takes cards already
learned and due. A `learning` session **consults no scheduler at all** — every
turn is `learning` or `relearning` and moves nothing (BR-141, BR-144). Computing
an interval and discarding it would be a number somebody eventually stores by
accident.

Finishing the chain is an **event**, not an answer: one atomic write of
`learned_at` plus a seeded schedule, which also locks the root's scheduler in the
same transaction (BR-13).

### status × end_reason is a matrix, and deliberately not a CHECK

Five statuses, seven end reasons, and the valid pairs live in
`StudySessionStatus.isValidWith()` — not in a database constraint. The schema
comment says why: an invariant that cannot be violated cannot be tested, and a
query that can never fire proves nothing. Invariant 12 is the enforcement.

Worth knowing which is which: `user_exit` means the user chose to leave;
`interrupted` means the app reopened and found a session from an earlier study
day; `scheduler_reset` and `scheduler_changed` are two different events and were
split precisely so a stale-generation check cannot misread one as the other.

## 6 · How errors are converted

`StudyRefusalReason` carries only refusals a user could act on; a genuine bug
stays a `DatabaseFailure`.

`nothingDueToReview` is the one to understand: **studying ahead is a rule, not a
missing feature** (BR-29). Nothing due means the schedule is working. The session
is refused and **no row is written** (BR-101, BR-145).

`modeHasNoContent` is shown **with its reason on the chooser**, never silently
hidden (BR-99, BR-154) — `guess` needs 5 distinct meanings, `match` needs 2
pairs, `fill` needs a card with an example. `modeNotSupportedByScheduler` is
never advertised as something Reset would unlock (BR-100).

## 7 · How to test it

`test/features/study/`. The scheduler tests assert the full action sets, the
stage sequences and the interval/ease tables value by value — those tables are
the business rule, so pinning them is not over-specification.

`test/database/invariant_queries.dart` covers 24 of the document's 37
invariants — the ones with an executable fixture. Q16–Q28, which cover much of
this feature's session and queue rules, are verified by
`verify_invariants.py` instead, which synthesises a violation and proves the
query fires. Two mechanisms, one rule set.

## 8 · Known gaps

- `StudyMode` has six members but `study_answers.mode` accepts five — `browse`
  writes no history row at all (BR-111), so the schema cannot hold one.
- `study_queue_items` has four bounded integer columns (`round ≥ 1`,
  `available_at ≥ 0`, `answers_in_session ≥ 0`, `remaining_ms` 0–20000) and
  **none of them has a CHECK**; they are policed only by invariants 17 and 21.
  Compare `app_settings.reminder_minute_of_day`, which *is* a CHECK. Two
  structurally identical bounded columns, one enforced by the database and one
  not.
- `study_answers.session_id` is the only `ON DELETE NO ACTION` foreign key in the
  schema. In practice the cascade from `cards` empties those rows first, so it
  never fires — but that is the application's precondition holding, not the
  database guaranteeing it.
- `SchedulerType.unknown` resolves to a null scheduler by construction: a deck
  written by a future build with a third algorithm is readable but not studiable.

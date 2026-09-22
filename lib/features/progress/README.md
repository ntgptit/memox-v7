# features/progress

Study progress, whole-library and per-deck (UC-12, UC-13, BR-182…BR-199). Read
`features/deck/README.md` first for the method.

## 1 · What business problem it owns

Two read-only screens: "how am I doing overall" and "how am I doing per deck".

It owns **no writes at all**, and that is structural rather than promised:
`ProgressRepository` and `ProgressDao` expose no write method. Adding one would
be a visible diff in a file whose whole purpose is not to have one (BR-188,
BR-190).

## 2 · Public entry points

| Kind | Where to read it |
|---|---|
| Routes | `RouteNames.progress`, and the per-deck drill-down |
| Screens | `ProgressScreen`, the deck-level view |
| Contract | `ProgressRepository` |
| Read models | `ProgressOverview`, `DeckActivityMetrics`, `ProgressActivityDay` |

## 3 · Data flow

Reads are `watch()` streams over `progress.drift`. Each screen gets **one**
snapshot per emission (AD-13), including the instant it was measured against.

The single most important thing to understand before changing any query here:

**The unit is a card-day, never an answer row.** One distinct card touched on one
local day. Drilling one card six times in an evening is one day of work on one
card, not six. This is BR-192, and it is implemented as a double `GROUP BY` in
SQL rather than a count — a raw answer count would read as "studied 6 things
today".

## 4 · Providers, by role

`presentation/providers/` is wiring. Controllers hold the selected range and the
snapshot.

`now` and the UTC offset are resolved **once per emission** and passed down
(BR-194, AD-16) — not re-read per event, and never read inside `domain/`.
`ProgressOverview` carries its own `nextLocalMidnight`, so a rollover timer waits
for the boundary the numbers were actually measured against rather than one
computed later by a controller.

## 5 · Where the business rules are

BR-182…BR-199. What the numbers mean:

- **`lastSevenDays`** — exactly 7 entries, oldest first, ending today. Empty days
  are zero-filled **as data, not gaps** (BR-196), and that filling is the
  domain's job, not the query's. A week with three idle days should look like a
  week with three idle days.
- **`currentStreakDays`** — consecutive local days with activity, anchored at
  today if active else yesterday, so one rest day pauses a streak rather than
  ending it. Deliberately **uncapped**, not clamped to the 7-day window (BR-197).
- **`hasLifetimeActivity`** — whether the user has ever answered anything. Not
  derivable from the window or the streak, both of which read empty for someone
  with months of history who took a break. It is what separates "come back, you
  have history" from "start now".
- **Learning vs Reviewing is an exhaustive, exclusive partition** (BR-186,
  BR-195): a card-day with any `learning` turn is Learning, full stop. Their sum
  equals the total **by construction**, not because two independently computed
  numbers happen to agree.
- **`activeDayCount` is not additive across decks** (BR-183). The same Tuesday
  active in two decks is still one day of study, so a total for that figure comes
  from a separate whole-scope aggregate and must never be summed from the rows.
  `activeCardCount` *is* summable, because a card lives in exactly one subtree.
- **History follows a card's current deck** (BR-185). Move a card and its whole
  history moves with it. "What did this deck look like in March" is explicitly
  not answerable in v1.
- **Both windows come from one statement** (BR-184), so switching 7↔30 days
  re-reads nothing and the summary cannot disagree with the rows.
- **Zero-activity decks stay in the list, sorted last** (BR-187), because "which
  decks did I neglect" is a question the list has to answer.
- **`browse` creates no card-day and holds no streak** (BR-193) — it writes no
  history row at all.

Out of scope for v1, and stated so nobody adds it by reflex: accuracy, score,
longest streak, goals, XP, heatmap, due forecast (BR-182).

## 6 · How errors are converted

`NotFoundFailure` when a named deck no longer exists. The distinction matters:
an empty level and a deleted deck render the same way if you let them, and
"this deck is quiet" is a different message from "this deck is gone".

Everything else is a mapped database failure. A `DriftException` never reaches a
screen, and no mapped error carries card content (BR-52).

## 7 · How to test it

`test/features/progress/`. `test/database/progress_query_plan_test.dart` is worth
knowing about: it proves by `EXPLAIN QUERY PLAN` that a *proposed*
`study_answers(answered_at)` index would change nothing, and that the existing
composite `idx_study_answers_card` already serves the Progress join as a covering
index. A debt item was empirically wrong and the test is the record of that.

## 8 · Known gaps

- A trashed card takes its whole history out of every Progress number via the
  shared active-row predicate (BR-250, BR-257). Restore brings it back at the
  card's current position — there is no snapshot of what the numbers were before.
- `ProgressPathSegment` is this feature's own type rather than Deck's, to avoid
  the coupling (AD-17).

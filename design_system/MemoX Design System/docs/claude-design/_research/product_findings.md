# Product findings

| | |
|---|---|
| **Status** | draft |
| **Purpose** | Research note behind the Claude Design handoff — product, use cases and business rules as found at base commit de1e862c |
| **Scope** | What memox does: data, rules, states, user actions across all eight features. Out of scope: current Flutter UI layout, widgets, theme, state-management mechanics |
| **Source of truth for** | — (derived research; docs/ and lib/ remain the sources) |
| **Depends on** | docs/product.md, docs/use-cases.md (UC-01..UC-22), docs/business-rules.md, docs/business-rules/study-mode.md, docs/master-flow.md, docs/architecture.md (AD-07/09/10/19/20/21/22), lib/features/**/domain/** |
| **Updated by task** | claude-design-handoff (no WBS id) |
| **Last updated** | 2026-09-16 |

## 1. Feature inventory

All eight `lib/features/` slices exist with domain layers (entities, use cases,
failures) SOURCE-CONFIRMED (`lib/features/{deck,card,study,progress,reminder,search,settings,trash}/domain/`).
`docs/master-flow.md` §6 says UC-05/UC-07 (review) were "not yet built" — this is
**stale**: that table is dated 2026-08-16 and `lib/features/study/domain/` now has
full use cases and a `study_refusal_failure.dart` enum. CONFLICT flagged in §8.

| Feature | Status | Evidence |
|---|---|---|
| Deck (tree, CRUD, move, reorder, templates, reset) | implemented | UC-01/02/03/07/08/09/22; `lib/features/deck/domain/usecases/` |
| Card (CRUD, flag, tag, import/export, detail/history) | implemented | UC-04/10/11/18/19; `lib/features/card/domain/` |
| Study (sessions, stages, modes, direction) | implemented | UC-05/14/15; `lib/features/study/domain/` |
| Progress (overview + by-deck) | implemented, v1 scope only | UC-12/13; BR-190/191 explicitly caps v1 (no accuracy, longest streak, goals, XP, heatmap, deck filter) |
| Reminder (daily due-only notification) | implemented | UC-17; `lib/features/reminder/` |
| Search (library-wide) | implemented | UC-20; `lib/features/search/` |
| Settings (study defaults, theme, language) | implemented, narrow scope | UC-16; product.md still calls Settings "placeholder" — DOCS-STALE, see §8 |
| Trash (soft-delete + restore) | implemented | UC-21; `lib/features/trash/` |
| Auth / accounts / sync | out of MVP | product.md "Explicitly out of MVP" |
| iOS | deferred | product.md |
| Media (image/audio) in cards | out of MVP | product.md |
| Card reverse direction (S3) | partial | Only closed for `self_assess`×`sm2`×reviewing (UC-15); other modes not reversible |
| StudyMode grading stages (match/guess/recall/fill) | implemented, direction-tied to `eight_box` | product.md frames these as "conceptually settled, not must/should/nice-classified" but code + BR-106..161 fully specify them |

## 2. Use cases per feature (goal · actions · constraints · refusals)

**Deck**
- UC-01 First launch / starter library: browse template manifest → pick a
  starter → pick a scheduler for the copy → get a personal copy immediately
  reviewable. Refusals: corrupt manifest (empty-state, manual create still
  works), one broken template file skipped individually, copy-in-progress
  failure rolls back entirely (no half-built tree).
- UC-02 Create root deck: name + mandatory scheduler choice, no silent
  default. Refusal: empty/too-long name, no scheduler chosen.
- UC-03 Rename/delete deck, change scheduler (root only, only before first
  answered turn). Deleting cascades descendants, cards, study state, history,
  sessions. Refusal: scheduler change attempted after lock — shown as locked
  with an explicit path to Reset, not hidden.
- UC-06 Deck list with progress: New vs Due counts kept separate, never
  merged; each root aggregates its whole subtree.
- UC-07 Reset learning progress (root only): user may pick a new scheduler in
  the same action. Keeps content and old history; wipes current schedule,
  due dates, mastery, open sessions; increments generation.
- UC-08 Create child element in a deck: the Create button offers different
  choices depending on the deck's `content_type` (unset/card/deck/root).
  First child created fixes the type.
- UC-09 Move a deck: blocked into itself/its descendant, into a card-only
  deck, across schedulers/generations, or past depth 10.
- UC-22 Reorder siblings (manual order only): move up/down among same-parent
  active decks; hidden when list is sorted any other way.

**Card**
- UC-04 Manage cards in a deck: add (front+back required), edit (content
  only, never touches schedule/history), delete (last card returns deck to
  `unset`), move between decks (same root only), bulk actions (select all
  respects current filter/search, not just loaded page; all-or-nothing).
- UC-10 Bulk import (CSV/TSV/XLSX or pasted text): Source → Preview → Import;
  in-memory parse, duplicate detection, header auto-mapping; commit is one
  transaction. Refusals: unreadable/non-UTF-8 file, empty source, zero valid
  rows after validation, target deck no longer valid at commit time.
- UC-11 Export cards (all-in-deck or selected scope, fixed at entry point):
  three formats (CSV default, TSV, XLSX); read-only, hands file to OS share
  sheet; closing the share sheet without picking a destination is a cancel,
  not an error.
- UC-18 Tag management: library-wide catalog with per-tag card counts,
  search, rename (may merge into an existing tag — explicit warning before
  confirming), delete (only unlinks, never deletes cards); filter by
  multiple tags is OR, combined with AND against status filter/search.
- UC-19 Card detail (read-only) + paginated review history (50/page,
  keyset), grouped by scheduler generation. Viewing a card is never a study
  turn.
- UC-20 Global search (deck names, card front/back, tag names only — not
  example/hint/pronunciation): 250ms debounce, decks-first then cards,
  exact→prefix→contains ranking.

**Study**
- UC-05 Review a deck (the core daily loop): two disjoint session kinds —
  *learning* (unlearned cards go through a fixed stage sequence the user
  does not choose) and *reviewing* (due cards go through exactly one
  user-chosen mode). Session created only by an explicit Study tap; never by
  badges/counts. Card limit fixed at session open (default 20, per-fetch cap,
  not a daily cap). Refusals: nothing due (positive empty state, no session
  created), stale generation (write rejected, session invalidated), write
  failure mid-session (retry same card, does not advance).
- UC-14 Study Home / entry: read-only snapshot listing root decks by
  Overdue→Due today→New, with a single Resume card if a same-day
  `in_progress` session exists.
- UC-15 Choose question direction (only for `sm2` × reviewing ×
  self_assess): Korean-first / Meaning-first / Mixed, locked once the session
  opens; mixed assigns direction per-card once at queue build time (not
  re-randomized).

**Progress**
- UC-12 Progress overview: current streak, today's Learning/Reviewing split,
  last-7-days bar (zero-filled), all read-only.
- UC-13 Progress by deck: library level (7/30-day selector + a row per root)
  drilling down to per-deck level; sorted by cards-studied descending.

**Reminder**
- UC-17 Daily reminder: off by default; enabling asks OS notification
  permission (never asked earlier); one summary notification per day only
  when `overdue + due-today > 0` at fire time; tapping opens Study Home
  only (never auto-opens a session).

**Settings**
- UC-16 App settings: Study defaults (card limit, new-card order),
  Appearance (theme: system/light/dark), Language (system/en/vi). A root
  deck may override study defaults; `Use app defaults` clears the override.
  Theme/language changes apply immediately, no restart.

**Trash**
- UC-21 Soft-delete + restore: deleting creates a batch + Undo snackbar;
  Trash lists batches split Cards/Decks with days-remaining; Restore asks
  for a target deck (same eligibility rules as Move); Undo reverses the
  exact batch to its old location without asking. Purge permanently deletes
  eligible batches (30×24h retention) at app start/resume/Trash-open.

## 3. Business rules (grouped; BR id · plain English · enforced where)

**Deck tree** — BR-55 max depth 10 (root = level 1), checked before write.
BR-56/57 root resolved via `root_deck_id`, never
`COALESCE(parent_deck_id, id)` (SOURCE-CONFIRMED `check_architecture.sh`
rule referenced; not independently re-verified in code this pass). BR-58 root
holds only sub-decks. BR-60/61/62 sub-deck starts `unset`; first child fixes
type atomically. BR-63/64/65 a deck never holds both cards and sub-decks.
BR-163 `content_type` is system-maintained, atomic with whatever
mutation removed/added the last child — no manual reset action exists.
BR-69/70/72 no cycles; can't move into self/descendant; no wrong-root
descendants.

**Scheduler selection & lock** — BR-11 root must choose `eight_box` or `sm2`
at creation, no default. BR-12 scheduler/version/config freely changeable
until `first_answered_at IS NOT NULL`; re-selecting the current scheduler is
a no-op (doesn't reseed tree, doesn't close sessions). BR-13 locked the
instant the *first card completes the new-learning stage sequence* (not the
first `scheduled` turn) — locking happens in the same transaction as that
completion. BR-14 unlocked scheduler change reseeds all card study state in
the tree. BR-73/74 no automatic state conversion between schedulers; moving
a subtree into an incompatible root is blocked, must be explicit reset.

**eight_box** — BR-15 forgotten→box 1, remembered→min(8, box+1). BR-16
interval table 1/2/4/8/16/32/64/128 days per box 1-8; due date = start of
local day N, not now+N*24h (AD-16). Box 8 is not a terminal "graduated"
state — cards keep re-cycling at 128-day intervals.

**sm2** — BR-17 action→quality: again=0, hard=3, good=4, easy=5. BR-18/19
ease factor recalculated *before* the interval multiplication (order is a
rule, not an implementation detail); floor ease_factor at 1.3.

**"Mastered"** (BR-88, derived, never a DB column) — `eight_box`: box=8;
`sm2`: interval_days>=128 (deliberately matched to box-8's interval so
"mastered" means the same real time-gap on both schedulers, not the SM-2
convention of 21 days).

**Turn kinds** (BR-75..78, BR-141..144) — Every answer row stores `kind`
explicitly (`learning`/`scheduled`/`relearning`), never derived from
before/after diffing (a box-8→box-8 `scheduled` remembered-turn looks
identical to a no-op relearning turn if inferred). Only `reviewing` sessions
produce `scheduled` turns that change the schedule; `learning` sessions never
touch `card_study_states` until the card **completes the last stage it
participates in** — that completion is an event, not a graded turn, and it
sets `learned_at`+initializes schedule at the lowest level (box 1 /
interval 1) with due date = start of next study day.

**Session kinds** (BR-142/BR-23/BR-24) — exactly two, never mixed: `learning`
= `learned_at IS NULL`; `reviewing` = `learned_at IS NOT NULL AND due_at <=
now`. Card limit (default 20) is a per-fetch cap, not a daily cap; fixed once
at session-open time (BR-139), later default changes don't affect a running
session.

**Session lifecycle** (BR-79..86, BR-164) — five statuses:
`in_progress/completed/abandoned/invalidated/failed`; five end reasons:
`user_exit/scheduler_reset/stale_generation/persistence_error/interrupted`.
Turns already written before an abnormal end are always kept. Generation
mismatch (BR-46/84) rejects the write entirely and invalidates the session —
protects against a stale session (left open while a Reset happened elsewhere)
silently un-resetting progress.

**Reset & generation** (BR-40..50, AD-09) — keeps deck/subtree/cards/media/
tags/content and old `study_answers`; wipes active schedule state (including
`learned_at`), all open sessions; `scheduler_generation` +1; run as one
transaction. Two DB invariants: exactly one active scheduler per tree at a
time (BR-48); all card state in a tree shares one generation (BR-49).

**Card content** — BR-07/08 front/back required, front ≤60 chars, back ≤240
chars (trimmed). BR-95 three optional fields (example/hint/pronunciation)
≤240 chars each. BR-09/10 editing content never touches study state/history.

**Display status** (BR-89..91, derived, never stored) — `new`
(`learned_at IS NULL`), `beginning` (interval <8 days), `reviewing` (>=8
days), `mastered` (BR-88 threshold). Not a state machine — can regress
`reviewing`→`beginning` after a lapse, that's normal.

**Flags & tags** (BR-92..94, BR-165..167) — flag is content: survives edit
and reset, system may only *set* it (auto-flag on hitting the 3-relearning
cap in self_assess, BR-104), never auto-clears. Tag: unique case-insensitive,
≤50 chars, max 10 tags/card. Bulk card mutations are all-or-nothing in one
transaction; "select all" respects current filter/search, not just the
loaded page, and selection is cleared whenever filter/search/sort/deck
changes.

**Import/export** (BR-168..181, AD-20) — Import target must be `unset` or
`card` sub-deck (never root, never `deck`-typed); duplicate key =
`front_folded + back_folded` scoped to the target deck only; import never
carries schedule (no due date/box/SM-2 state — imported cards are new).
Export is strictly read-only, six canonical content fields only (never IDs,
timestamps, flags, scheduler data, history); artifact is transient, handed
to the OS share sheet, never claims "saved".

**Progress** (BR-182..199) — counting unit is a *card-day*, distinct
`(card, local day)` pair — six same-evening answers to one card count as
one card-day. v1 reports exactly four numbers: unique active cards, active
days, Learning card-days, Reviewing card-days — explicitly excludes
accuracy, longest streak, goals, XP, heatmap (BR-191). Streak keeps holding
if yesterday was active but today isn't yet (doesn't reset to 0 mid-day).
Activity is attributed to a card's *current* deck location, not where it was
answered — moving a card moves its whole history display with it.

**Reminder** (BR-218..229, AD-21) — off by default; permission requested
only after user enables; fires at most one summary/day, only if
`overdue+due-today>0` *measured at fire time* (not at schedule time);
content may name the single most-urgent root deck + total count + remaining
deck count, never per-card content; tapping opens Study Home only.

**Settings** (BR-210..217) — `app_settings` is a single typed row, no
JSON/key-value blob. Two-tier resolution: root-deck override wins over app
default; `Use app defaults` clears the override. Changing a default only
affects sessions *created after* the change.

**Search** (BR-247..255) — covers exactly four fields (deck name, card
front, card back, tag name); explicitly excludes example/hint/pronunciation
and any scheduler/history data; results grouped Deck-then-Card, exact→
prefix→contains ranking within each group; a card matching multiple fields
produces exactly one result row.

**Trash** (BR-256..267, AD-22) — soft-delete only (no hard delete via normal
flows); deleting a deck marks it + all currently-active descendants under
one batch; a descendant already in Trash from an earlier batch is untouched
(no re-batching); 30×24h retention; restore requires an explicit target
(same eligibility rules as Move) except Undo, which restores to the exact
old location without asking; bulk select in Trash cannot mix cards and
decks in one action.

**Privacy** (BR-51..54, AD-08) — deck/card content, notes, history, import
files, images/audio, backups are all private data; content must never be
logged at any level (IDs may be); media stored in app-private directory;
export/backup only run on explicit user request.

## 4. Validation limits

| Field | Limit |
|---|---|
| Deck name | non-empty after trim, ≤200 chars |
| Card front | non-empty after trim, ≤60 chars |
| Card back | non-empty after trim, ≤240 chars |
| Card example/hint/pronunciation | optional, ≤240 chars each |
| Tag name | non-empty after trim, ≤50 chars, case-insensitive unique |
| Tags per card | max 10 |
| Deck tree depth | max 10 levels (root = level 1) |
| Session card limit | default 20 (configurable via settings, per-fetch, not daily) |
| Reminder time | stored as minutes-since-midnight local, 0-1439, default suggestion 1200 (20:00) |
| Import file encoding | UTF-8 / UTF-8 BOM only |
| History page size | 50 rows, keyset-paginated |
| Progress intervals | exactly two: 7 days and 30 days, no custom date range |
| `recall` mode timer | 20 seconds interaction time (pauses when backgrounded) |
| `self_assess` relearning cap | 3 repeats before card leaves queue (flags the card) |

## 5. Lifecycles / state machines

- **Deck `content_type`**: `unset → card` or `unset → deck` (first child
  created); back to `unset` when the last active direct child is removed
  (delete/move/soft-delete); root is permanently `deck`. All transitions are
  atomic with the child mutation, system-maintained, no manual control.
- **Scheduler lock**: unlocked (`first_answered_at IS NULL`, free changes) →
  locked (first new-learning completion sets it in the same transaction) →
  only unlockable via Reset (which also bumps generation).
- **`scheduler_generation`**: starts at 1, +1 per Reset; every card study
  state, session, and answer row carries its generation; a write from a
  stale generation is rejected and its session invalidated.
- **Card display state** (derived, not stored): `new` → `beginning` →
  `reviewing` → `mastered`, can regress from `reviewing`/`mastered` back to
  `beginning` after a lapse (not a strict forward progression).
- **Flag**: unset → set (user action, or system auto-set on relearning cap);
  never auto-cleared by system.
- **Study session status**: `in_progress` → one of `completed` (queue
  emptied) / `abandoned` (user exit, or reopened on a different study day) /
  `invalidated` (stale generation, or scheduler reset/change while open) /
  `failed` (unrecoverable write error).
- **Session kind**: `learning` (fixed stage sequence per scheduler, no
  schedule changes) vs `reviewing` (single user-chosen mode, schedule
  changes on first turn of each card, `relearning` on repeats).
- **New-learning stage sequence**: `eight_box` → browse→match→guess→
  recall→fill; `sm2` → browse→self_assess. A stage with no eligible cards
  is skipped (recorded), not shown empty.
- **Queue item status** within a stage: pending → answered (leaves queue) or
  re-enrolled into a later round (grading modes) / re-inserted after 3 cards
  (self_assess, capped at 3 repeats).
- **Trash batch**: active → soft-deleted (tombstoned, `deleted_at` set) →
  restored (tombstone removed, re-parented) OR purged (hard-deleted,
  cascades) after 30×24h eligibility, OR undone (immediately, exact batch,
  no target picker).
- **Tag rename→merge**: renaming to a folded name not owned by another tag
  just relabels (same id, same links); renaming to a folded name that
  collides with an existing tag merges (source's links repointed to target,
  deduped, source row deleted) — all in one transaction.
- **Reminder**: off (default) → enabling (permission requested) → on
  (scheduled inexact daily alarm) → fires only if due workload > 0 at fire
  time → reschedules for next day regardless.

## 6. System-initiated behaviour

SOURCE-CONFIRMED file presence (not fully read line-by-line this pass —
DERIVED behaviour summary from file names + UC/BR cross-references):
- `lib/app/startup/fixture_seeder_widget.dart` — seeds starter deck
  templates at app startup (currently development/test fixtures per BR-87,
  not production content).
- `lib/app/startup/trash_sweeper_widget.dart` — runs auto-purge of
  eligible Trash batches at app start/resume (BR-264), idempotent.
- `lib/app/startup/reminder_reconciler_widget.dart` — reconciles the
  reminder schedule at startup (handles timezone changes, reboots, app
  updates) per BR-227 (idempotent scheduling).
- Progress screen midnight rollover: a one-shot timer set from the current
  snapshot's expiry re-triggers a re-read at local midnight with no DB write
  (BR-199).
- Deck-list due/overdue classification recomputes on read at local midnight
  boundary crossing, no DB write (BR-161).

## 7. Edge cases

- A card with zero data for a grading stage (e.g., no `example` for `fill`)
  is skipped **with a record**, not removed from the deck, and still shows
  in other stages it qualifies for (BR-114).
- A `match`/`guess`/`recall`/`fill` round always ends in an all-correct
  final round (that's the round-exit condition), so the *first* attempt is
  the only signal that means anything about memory — this is called out
  explicitly as why the "last answer of the chain" cannot be used for
  anything (product.md, BR rationale after BR-144).
- Deleting the app-recovered ("interrupted") session vs. user-initiated exit
  are distinguished (`interrupted` vs `user_exit`) — OS process reclaim is
  not treated as the user giving up.
- Reopening the app mid-session on the *same* study day resumes the exact
  queue/position/turn count; a *different* study day auto-abandons the old
  session (`end_reason = interrupted`).
- Moving a card/subtree across roots with the same scheduler+generation
  "by coincidence" is still blocked (BR-165) — coincidental equality is not
  treated as a valid mapping.
- Streak "holds" (doesn't zero) if today has no activity yet but yesterday
  did — copy must communicate "held" vs "lost" distinctly (UC-12 A1).
- `guess` distractors are pulled from cards already learned (or currently in
  the same session), never from never-seen cards — the fix is described as
  a deliberate change ("BR-122 changed source") because early sessions with
  too few due cards would otherwise disable `guess` almost always.

## 8. Docs vs code conflicts

1. **`docs/master-flow.md` §6 says UC-05/UC-07 (Study/Reset) are "chưa xây"
   (not yet built)** as of its 2026-08-16 update. CONTRADICTED by code:
   `lib/features/study/domain/` has full use cases (open/start/resume/end
   session, submit answer, advance stage, etc.) and
   `study_refusal_failure.dart` enumerates production refusal reasons. This
   doc is stale; treat `docs/wbs-study.md` as authoritative for Study's
   build status, not `master-flow.md`.
2. **`docs/product.md` still calls Settings "chỉ là scaffold/placeholder"**
   ("Settings vẫn chỉ là scaffold/placeholder — có tab và route không có
   nghĩa feature đã hoàn thành") while `docs/use-cases.md` UC-16 and
   `docs/business-rules.md` BR-210..217 fully specify Settings (study
   defaults, theme, language) and `lib/features/settings/domain/` exists.
   The task instructions flagged this exact staleness in advance; confirmed
   here from both docs and code.
3. Minor, explicitly self-documented in `master-flow.md` §6 "Ba chỗ tài
   liệu và code đã lệch": UC-04 doesn't list BR-93/BR-95 (flag/tag) in its
   own Business Rules line though those BRs declare `Related: UC-04`; UC-06
   doesn't mention search even though a search feature/UI exists; UC-01
   describes a starter-library browsing screen that (per that doc, dated
   2026-08-16) doesn't exist yet — only fixture auto-seeding does. Not
   independently re-verified against current `lib/features/deck/` UI code
   this pass (UI is out of scope per this note's brief); flagged as-is from
   the docs' own admission.

## 9. Unknowns

- UNKNOWN whether `docs/product.md`'s starter-library manual-browse screen
  (UC-01 steps 3-7: choosing a starter deck and scheduler explicitly from a
  library UI) has since been built, given master-flow.md's note that only
  auto-seeding existed as of 2026-08-16 and Subagent A/C's UI-focused
  research is better positioned to confirm current screen existence — this
  note deliberately does not describe UI.
- UNKNOWN precise current wording/labels users see for refusal states (e.g.
  exact copy for BR-100's "must not suggest Reset" rule) — only the
  constraint is confirmed, not shipped copy, since ARB/string files were out
  of scope for this pass.
- UNKNOWN whether reverse-direction (S3) has expanded beyond the single
  `sm2`×reviewing×self_assess case since UC-15/BR-203..209 were written —
  product.md explicitly calls this "half closed," and no later doc revision
  claims further expansion.
- DERIVED-only (not independently traced through code this pass): §6 System-
  initiated behaviour and the `check_architecture.sh`/BR-57 enforcement
  claim — confirmed by file existence and doc citation, not by reading full
  implementation logic line-by-line, per the 30-45 tool-call budget.

## 10. Coordinator reconciliation

Added by the coordinator after cross-checking this note against source; the
handoff files follow these corrections.

- **§3 Session lifecycle lists five end reasons; there are seven.** BR-80 is
  stale. `StudySessionEndReason` (`study_session_status_model.dart`) adds
  `scheduler_changed` (BR-164) and `content_deleted` (BR-259). Legal pairs are
  enforced by `StudySessionStatus.isValidWith`: abandoned → `user_exit` |
  `interrupted`; invalidated → `scheduler_reset` | `scheduler_changed` |
  `stale_generation` | `content_deleted`; failed → `persistence_error`.
- **§9 starter library — resolved: built.** Route `starter`
  (`lib/app/router/route_paths.dart:38`), `starter_library_screen.dart`,
  `InstallDeckTemplateUseCase(template, {schedulerType, allowDuplicate})` and
  its ARB copy all exist. `fixture_seeder_widget.dart` auto-installs templates
  **only when the environment is development**; production starts empty.
- **§6 system behaviour — confirmed for the seeder** (read in full, see above).
- **Lock trigger (§3) is correct** and wins over stale sources: BR-13 plus
  `study_lifecycle_repository_impl.dart:123` lock at the first learned card;
  the older BR state table and a `decks.drift` comment still say "first
  scheduled review".
- **§7 edge case "`fill` needs an example"** is confirmed in
  `fill_mode.dart:70`, but the prompt is the card's back and the grading target
  its front (`fill_mode.dart` `grade`), so the example no longer takes part in
  the question — recorded as an open product question in the handoff.
- **Review mode sets** (BR-146) — `eight_box`: match / guess / recall / fill;
  `sm2`: self_assess only, entered directly with a direction choice.

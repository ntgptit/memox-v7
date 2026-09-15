# MemoX — Product Context

| | |
|---|---|
| **Status** | draft |
| **Purpose** | Handoff for Claude Design — what MemoX is, what a user can do, which rules must hold and which states data moves through |
| **Scope** | Product behaviour extracted from the repository at base commit `de1e862c`. Out of scope, on purpose: the current Flutter UI — layout, components, theme, navigation mechanics — so the redesign is not anchored to it |
| **Source of truth for** | — (derived snapshot; `docs/` and `lib/` remain the sources and win on any disagreement) |
| **Depends on** | — (self-contained; read this file before the other four) |
| **Updated by task** | claude-design-handoff (no WBS id) |
| **Last updated** | 2026-09-16 |

## Reading this handoff

| File | Answers |
|---|---|
| `PRODUCT_CONTEXT.md` | What exists, for whom, which rules hold, how entities change state |
| `FEATURE_SCREEN_REQUIREMENTS.md` | Per product area: goal, information, actions, states, constraints |
| `API_CONTRACT.md` | The exact data each area receives and the commands it can issue |
| `DATABASE_DDL.sql` | The persistent schema — what is stored, what is internal |
| `SAMPLE_DATA.json` | Synthetic records shaped like `API_CONTRACT.md`, including edge cases |

**Evidence.** Statements are confirmed in source unless marked **DERIVED** (an
inference, with its basis) or **UNKNOWN** (needs product confirmation). IDs such
as `BR-13`, `UC-05`, `AD-19` point at the repository's business-rule, use-case
and architecture documents. They exist for traceability; a design never needs
to show them.

**What this is not.** It does not describe the current screens. Where the
product owner already settled a user-visible behaviour — "never claim an
exported file was saved" — it appears as a constraint. How to satisfy it is a
design decision.

---

## 1. Product overview

MemoX is a flashcard app for people who teach themselves vocabulary on a phone,
in short and irregular sessions. The user builds decks of two-sided cards, or
copies a starter deck, and the app decides **when** each card should come back
using a spaced-repetition algorithm chosen per deck. Studying happens in
sessions; progress screens report recent activity.

| Aspect | Decision |
|---|---|
| Target users | Self-learners studying vocabulary; exam takers with large word lists and a deadline. Not classrooms, not teacher-managed courses |
| Core value | Review the right word at the right time, fully working offline |
| Data posture | Local-first. Everything lives on the device; every feature works in airplane mode |
| Accounts | None. One local profile. No login, no sync, no sharing |
| Network | None used by the app. A standalone backend exists in the repository but the app does not call it (see `API_CONTRACT.md` appendix) |
| Platforms | Android is the release target. A web build exists only as a development and test channel. iOS is deferred |
| UI languages | English and Vietnamese, plus "follow the system" |
| Card content | Any script. The product is built around **Korean vocabulary**: the reverse-direction option is framed as Korean ↔ meaning, the `fill` mode asks the learner to type the term, and Korean fonts ship with the app. Starter fixtures are English→Vietnamese and Korean→romanisation |
| Privacy | Card content, notes, study history, imports and exports are private data. Nothing leaves the device unless the user explicitly exports |

---

## 2. Core concepts

| Concept | Meaning |
|---|---|
| **Deck** | A named container in a tree. Up to **10 levels**; the top-level deck is level 1 |
| **Root deck** | A top-level deck. It owns the review algorithm, the reset counter (generation) and the study options for its whole tree. It holds only sub-decks, never cards |
| **Sub-deck** | Any deck below a root. At any moment it holds **either cards or sub-decks, never both** |
| **Content type** | What a deck currently holds: `unset` (empty), `card`, or `deck`. Maintained by the system, never chosen by the user |
| **Card** | A term (`front`, ≤60 chars) and its meaning (`back`, ≤240 chars), with optional `example`, `hint`, `pronunciation` (≤240 each), a user flag, and up to 10 tags |
| **Tag** | A library-wide label, unique regardless of letter case, ≤50 chars. Not owned by any deck |
| **Review algorithm (scheduler)** | Decides **when** a card returns: `eight_box` or `sm2`. Chosen once per root deck, locked after the first card finishes learning |
| **Study mode** | Decides **how** a card is asked: `browse`, `self_assess`, `match`, `guess`, `recall`, `fill` |
| **Learning session** | Takes cards not yet learned and walks them through a fixed sequence of study modes set by the algorithm |
| **Review session** | Takes learned cards that are due and asks them in one study mode the user picks |
| **Learned** | A card has finished its learning sequence. Only then does it get a schedule |
| **Due / Overdue / Due today** | A learned card whose due time has passed. Overdue = due before the start of today (local time); due today = due since the start of today |
| **Scheduled** | A learned card whose due time is still in the future — resting, nothing to do |
| **Card display state** | `new` · `beginning` · `reviewing` · `mastered`. A label computed from the schedule, never stored |
| **Generation** | A per-root counter. "Reset learning progress" increments it; history from earlier generations is kept and labelled |
| **Card-day** | Progress counting unit: one card studied on one local day, however many times |
| **Trash batch** | One deletion the user performed. Deleted items stay recoverable for 30 days |
| **Local study day** | Day boundaries are local midnight. Instants are stored in UTC; due dates fall on local midnight |

**Terminology trap — two meanings of "mode".** The current app copy calls the
*review algorithm* "Study mode" ("Eight boxes", "SM-2"), while the question
formats are also called modes ("Browse", "Match"…). This handoff keeps the two
apart: **review algorithm** versus **study mode**. User-facing wording is a
design decision.

**Terminology trap — "learned".** `learned` above means "finished the learning
sequence". One deck read-model also carries a `learnedCardCount`, which counts
**mastered** cards (box 8 / interval ≥128 days). `API_CONTRACT.md` names it
exactly as the source does and flags it.

---

## 3. Feature inventory

Everything below is implemented at base commit `de1e862c`.

| # | Feature | What it does |
|---|---|---|
| F1 | Deck library | Browse the deck tree, see per-deck workload and progress, create / rename / move / reorder / delete decks |
| F2 | Starter library | Copy a ready-made deck template into the user's library |
| F3 | Cards | Create, edit, flag, tag, move and delete cards; filter, search and bulk-act on a deck's cards |
| F4 | Tag catalog | See every tag with its card count; rename (with merge) and delete tags |
| F5 | Card detail and history | Read one card completely, with its current schedule and full review history |
| F6 | Import | Bring cards into a deck from CSV / TSV / XLSX or pasted text, with preview and duplicate detection |
| F7 | Export | Hand a deck's cards (all, or a selection) to the system as CSV / TSV / XLSX |
| F8 | Library search | Search deck names, card fronts and backs, and tag names across the whole library |
| F9 | Study home | See which root decks need work and resume an unfinished session |
| F10 | Study sessions | Learn new cards through a stage sequence; review due cards in a chosen mode; see a summary |
| F11 | Study options | Cards per session and new-card order — app-wide defaults with a per-root-deck override |
| F12 | Algorithm control | Change the review algorithm while unlocked; reset learning progress |
| F13 | Progress overview | Current streak, today's activity, the last seven days |
| F14 | Progress by deck | 7- and 30-day activity per deck, with drill-down through the tree |
| F15 | Settings | Theme, language, study defaults, reset app options |
| F16 | Daily reminder | One opt-in notification per day when reviews are due |
| F17 | Trash | Restore or permanently delete deleted decks and cards; automatic purge after 30 days |

**Not in the product** — do not design for these:

- accounts, login, profile, sync, sharing decks between users
- images or audio in cards
- accuracy, correct rate, longest streak, goals, XP, points, heatmaps, celebration effects, deck filter on the overview, sharing progress (BR-191)
- custom date ranges in Progress — only 7 and 30 days exist (BR-184)
- reviewing a card before it is due (BR-145)
- backup / restore of the whole library — export is content only, without schedule or history (BR-175)
- tag hierarchy, tag colours, shared taxonomies
- searching inside `example`, `hint`, `pronunciation` (BR-247), or accent-insensitive search (`cong` does not find `công`)
- a manual way to change a deck's content type (BR-163)

---

## 4. Use cases by feature

Each block lists the user goal, the actions that exist, and the constraints
that most shape design. Full rules are in §5.

### F1 · Deck library (UC-02, UC-03, UC-06, UC-08, UC-09, UC-22)

**Goal.** Organise vocabulary into a tree and see at a glance where work is waiting.

**Actions**
- Browse the top level (root decks) or any deck's direct children.
- Per deck, read: total cards, new, due (split overdue / due today), mastered, sub-deck count, algorithm, schedule status (`notDue` / `dueToday` / `overdue` with number of overdue days).
- Per level, read the sums of those counts across the decks shown.
- Filter the level: all decks, or only decks with due cards.
- Sort the level: manual order, date added (newest first), name (A→Z), most due cards, progress (least mastered first).
- Create a root deck — name and review algorithm are both required.
- Create a sub-deck inside a deck that can hold sub-decks.
- Rename a deck.
- Move a sub-deck under another deck; every candidate target comes with an eligibility reason.
- Reorder a deck before or after a sibling (manual order only).
- Delete a deck to Trash, after seeing how many descendant decks and cards go with it; undo right after.
- Change the review algorithm of a root deck while it is unlocked.
- Reset learning progress of a root deck.
- Start studying any deck (root or sub-deck) and open its study options.
- Reach the starter library, library search, tag catalog and Trash.

**Constraints**
- A root deck holds only sub-decks. A sub-deck holds cards or sub-decks, never both. An empty sub-deck (`unset`) accepts either as its first child (BR-58…66).
- Maximum depth 10, checked before anything is written (BR-55).
- A sub-deck cannot move into itself or its descendants, into a deck holding cards, past depth 10, under its current parent, or into a tree with a different algorithm or generation. Root decks cannot be moved (BR-70, BR-74, BR-55).
- Deck name: not empty after trimming, ≤200 characters.

### F2 · Starter library (UC-01)

**Goal.** Start with content instead of an empty app.

**Actions**
- See the available templates: title, content language, card count, content source.
- Add a template to the library, choosing the review algorithm; the template suggests a default.
- Deliberately add a second copy of a template already in the library, after confirming.

**Constraints**
- Adding creates a normal, independent deck tree. Later template versions never overwrite a copy (BR-33…36).
- Adding the same template version again copies nothing unless the user explicitly asks for a second copy (BR-37, BR-38).
- Current templates are development and test fixtures. They must be presented as practice content, not published course material (BR-87).
- A fresh production install opens with an **empty** library; nothing is inserted automatically. (Development builds auto-seed the fixtures; that is not product behaviour.)

### F3 · Cards (UC-04)

**Goal.** Create and maintain the cards of a deck.

**Actions**
- List the cards of a card-holding deck. Filter by All / Due / New / Flagged; search within the deck; filter by one or more tags; sort by newest or due soonest.
- Read the counts behind each filter, and the mastered-of-total progress of the deck.
- Create a card: front and back required; example, hint and pronunciation optional.
- Edit a card's content.
- Flag / unflag a card.
- Add a tag by name (reuses an existing tag regardless of case, otherwise creates it); remove a tag.
- Move a card to Trash, with undo.
- Open a card's read-only detail.
- Multi-select: select individual cards, or **select all** cards matching the current filter, search and tags; then move them to another deck, move them to Trash, set or remove the flag, add a tag, or export them.
- Import cards into the deck; export the deck's cards.

**Constraints**
- Cards live only in sub-decks whose content type is `unset` or `card` (BR-58, BR-63).
- Editing content never changes the schedule or the history (BR-10).
- Moving cards: only between sub-decks of the **same root**, to a `unset` or `card` deck other than the source; schedule, history, flag and tags travel with the card (BR-165).
- Bulk actions are all-or-nothing; one failing card rejects the whole batch (BR-166).
- "Select all" covers the whole result set, not just what has been loaded. Changing filter, search, sort, tags or deck clears the selection; a successful mutation clears it; a failed one keeps it (BR-167).
- In-deck search matches `front` or `back` by containment, ignoring case but not accents.
- A card carries at most 10 tags; a tag name is ≤50 chars and has no control characters.

### F4 · Tag catalog (UC-18)

**Goal.** Keep the library's labels tidy.

**Actions**
- List all tags, sorted A→Z by case-folded name, each with its number of active cards (zero is allowed).
- Search tags.
- Rename a tag. If the new name matches another tag, the two **merge** — the user is warned before confirming.
- Delete a tag. This removes the tag from its cards and never deletes a card; confirmation states how many cards lose the tag.

**Constraints**
- Tags are library-wide, never per deck (BR-93, BR-230).
- A merge keeps the target tag's id and spelling and can never push a card over 10 tags (BR-234).
- Catalog operations never touch card content, flags or study data (BR-236).
- Cards in Trash are not counted, but keep their tag links for restore (BR-237).

### F5 · Card detail and history (UC-19)

**Goal.** Inspect one card completely, and see how it has been studied.

**Actions**
- Read front, back, the optional fields that have values, tags, flag.
- Read the current schedule: display state, due time, learned time, last answered time, answer count, lapse count, and the algorithm's own fields (box for `eight_box`; ease factor, interval and repetitions for `sm2`).
- Page through the review history, newest first, 50 events per page.
- Go to edit the card.

**Constraints**
- Viewing is read-only and never counts as studying (BR-239).
- Each history event shows its **stored** values: time, study mode, kind, action, timeout reason, hint used, schedule before→after according to the algorithm the event was recorded under, next due time (BR-242).
- History is grouped by generation, and each group is identified in text, not by colour alone (BR-243).
- Empty history is a valid state (BR-244). A card that no longer exists shows a typed not-found state (BR-245).
- No aggregates here: no accuracy, score or streak (BR-243).

### F6 · Import (UC-10)

**Goal.** Bring many cards from a file or pasted text into one deck.

**Actions**
- Pick a source: a file (CSV, TSV, XLSX) or pasted text.
- Say whether the first row is a header; map each column to `front`, `back`, `example`, `hint`, `pronunciation`, `tags`, or nothing. Known header names are mapped automatically.
- Preview every row with its status: ready · invalid (with reasons) · duplicate of a card already in the deck · duplicate of an earlier row · blank.
- Choose whether duplicates are included.
- Confirm, and see the outcome: how many imported and how many duplicates skipped; or that no cards were added; or that the import failed.

**Constraints**
- The target must be a sub-deck of content type `unset` or `card`, re-checked at the moment of writing (BR-168).
- A mapping is complete only when both `front` and `back` are mapped. Each row needs both after trimming; card and tag rules are the same as manual entry (BR-169).
- Tags inside one cell are separated by `;` (BR-169, BR-176).
- Duplicates are identified by case-folded front + back, within the target deck and within the source; cards in other decks never count (BR-170).
- Everything is written in one transaction or nothing is; imported cards are **new** — no schedule, no history (BR-171).
- Importing at least one card into an `unset` deck makes it a `card` deck (BR-172).
- UTF-8 (with or without BOM) only; other encodings are refused with guidance (BR-173).

### F7 · Export (UC-11)

**Goal.** Take a deck's cards out of the app as a file.

**Actions**
- Export all cards of the deck, or the current selection.
- Choose CSV (default), TSV or XLSX.
- Hand the file to the system share mechanism, or cancel.

**Constraints**
- Exactly six columns, headers in lowercase English and never localised: `front, back, example, hint, pronunciation, tags` (BR-175, BR-179).
- No ids, timestamps, flags, schedule or history — this is content transfer, not backup (BR-175).
- "All" means every direct card of the deck, ignoring filter, search and sort (BR-174).
- If any selected card was deleted or moved meanwhile, the whole export fails; an empty scope is refused (BR-174).
- Export is read-only and does not clear the selection (BR-178).
- The file name comes from the sanitised deck name plus a date (fallback `cards`) (BR-180).
- Closing the share mechanism is a cancel, not an error. The app must never say the file was *saved* — only that it was handed to the system (BR-181).

### F8 · Library search (UC-20)

**Goal.** Find a deck, a card or a tag anywhere in the library.

**Actions**
- Type a query; read results in two groups, decks first, then cards; load more.
- Open a deck result (goes to that deck) or a card result (goes to the card's read-only detail).

**Constraints**
- Searches exactly four fields: deck name, card front, card back, tag name (BR-247).
- Case-insensitive, accent-sensitive (BR-248).
- Ranking: exact match, then prefix, then contains; stable between reads (BR-250).
- All deck results come before any card result (BR-251). A card matching several fields or tags appears once; when it matched through a tag, the tag name is provided (BR-252).
- Each result carries its deck path. Trashed content never appears. Results update live when data changes (BR-254).
- An empty query shows the initial state and runs no search. Typing is debounced 250 ms; clearing takes effect immediately (BR-249).

### F9 · Study home (UC-14)

**Goal.** Decide what to study right now.

**Actions**
- See every root deck with its whole-tree workload: overdue, due today, new, total cards.
- Resume today's unfinished session.
- Open a deck's study entry.
- With no decks at all: go to the starter library. With decks but no cards: go to the library.

**Constraints**
- Only root decks, aggregated over their subtree (BR-201).
- Order: overdue ↓, due today ↓, new ↓, then name, then id. Decks with no workload stay in the list, last (BR-201).
- Three distinct loaded states: no root decks · root decks without any card · decks with cards (even when all workloads are zero, which is normal, not an error or an achievement) (BR-202).
- Looking at this area never writes anything and never starts a session (BR-200).
- Resume is offered only for a session that is in progress, started today (local), still in the root's current generation, and has cards left (BR-200).

### F10 · Study sessions (UC-05, UC-15)

**Goal.** Learn new cards and keep learned cards fresh.

**Actions**
- For a deck (root or sub-deck), see how many cards are new and how many are due.
- **Learn**: start a learning session when new cards exist.
- **Review**: start a review session when due cards exist.
  - `eight_box` decks: choose one of `match`, `guess`, `recall`, `fill`. Each option shows how many cards it can take; unavailable options say why (needs cards with an example · needs five different meanings · needs at least two pairs).
  - `sm2` decks: only `self_assess` exists, so there is no mode choice; instead choose the **question direction** — term first, meaning first, or mixed — which is locked for the session.
- If a session from today is still open: continue it, or start learning / review (which abandons the open one).
- Answer turns; leave at any time; see the session summary.

**Constraints**
- Learning and review never mix cards (BR-142). Review cannot start with nothing due, and nothing allows reviewing early (BR-145). Nothing due is a normal state, not an error (BR-29).
- Cards per session: the effective card limit (1–200, default 20), fixed when the session opens. Sessions per day are unlimited (BR-24, BR-139).
- Order: learning follows the new-card order (`created` or `random`); review follows due time, oldest first (BR-23).
- The learning sequence depends on the algorithm (BR-110): `eight_box` → browse, match, guess, recall, fill · `sm2` → browse, self_assess. A stage no card can take is skipped (BR-99).
- A learning session writes history but changes no schedule until a card completes the last stage it takes part in. Then the card becomes learned, starts at the lowest level, and is due at the start of the next local day (BR-144).
- In review, a card's first answer is `scheduled` and moves its schedule; any repeat is `relearning` and does not (BR-141).
- Every answer is saved the moment it is given; a result is shown only once saved; a failed save does not advance and can be retried (BR-25, BR-157).
- A session started before a reset cannot write after it; it ends as invalidated (BR-84). A session whose deck or cards go to Trash ends as invalidated (BR-259).
- The app killed by the OS mid-session resumes the same day; an open session from an earlier day is closed as interrupted (BR-103).

**How each study mode behaves**

| Mode | Used in | Asks | Result |
|---|---|---|---|
| `browse` | learning (first stage, both algorithms) | Shows front and back together | No grading, no history. Moving forward completes the card for the stage; going back to earlier cards of the same round is allowed and changes nothing (BR-111, BR-155) |
| `self_assess` | `sm2` learning and review | Shows the prompt; the user reveals the answer, then grades themselves | The user picks one of the algorithm's actions: `again`, `hard`, `good`, `easy`. A forgotten card comes back after at least 3 other cards; after 3 repeats it leaves the queue and is **flagged** automatically (BR-26, BR-104). In review, the direction chosen decides whether front or back is the prompt (BR-204) |
| `match` | `eight_box` learning and review | Terms and meanings to pair up, at most 5 pairs at a time | Binary per card. Needs at least 2 pairs for the stage. A wrong pair keeps the card on the board and sends it to the next round (BR-118, BR-153, BR-156) |
| `guess` | `eight_box` learning and review | A term with exactly 5 meanings to choose from | Binary; only the first choice counts. Needs 5 distinct meanings among the session's cards (BR-121…126) |
| `recall` | `eight_box` learning and review | A term, with 20 seconds to recall it | Revealing before time runs out leads to a self-check with two choices — remembered / forgot — and advances automatically. Time running out counts as wrong and waits for the user to continue. The timer pauses when the app is in the background (BR-128…133, BR-159, BR-160) |
| `fill` | `eight_box` learning and review | The meaning (optionally with the card's hint); the user types the term | Correct when the typed text equals the front ignoring case and surrounding spaces, not accents. An empty answer is ignored. Using the hint is recorded but changes nothing. Only cards that have an `example` can take this mode (BR-134…138) |

Rounds: `match`, `guess`, `recall` and `fill` repeat in rounds with the cards
answered wrong, until a round has no wrong answer (BR-115, BR-119). For
`eight_box`, wrong → `forgotten`, right → `remembered` (BR-107).

**Session summary** reports: session kind, how it ended (status and reason),
cards that finished learning or were reviewed, cards answered, wrong turns and
total turns.

### F11 · Study options (UC-15, BR-147, BR-211…213)

**Goal.** Control session size and the order of new cards.

**Actions**
- Set app-wide defaults (in Settings): card limit, new-card order.
- Set an override on a root deck; clear it to follow the app defaults again.

**Constraints**
- Options belong to the root deck; sub-decks always use their root's options.
- Card limit is an integer 1–200 (default 20); new-card order is `created` (default) or `random`.
- A change affects only sessions opened afterwards, and the user must be told so where the change is made (BR-213).

### F12 · Algorithm control (UC-03, UC-07)

**Goal.** Pick the right algorithm, or start a deck's learning over.

**Actions**
- Change the algorithm of a root deck while it is unlocked.
- Reset learning progress of a root deck, choosing the algorithm for the new cycle (the same or the other one).

**Constraints**
- A root deck is **unlocked** until the first card of the current generation finishes learning; then it is **locked** (BR-12, BR-13).
- Changing while unlocked re-initialises every card's schedule in the tree and closes any open session as invalidated. Choosing the current algorithm is a no-op (BR-12, BR-14, BR-164).
- Reset keeps decks, sub-decks, cards, tags, notes and past history; it removes every card's schedule, due date and progress and any open session; all cards return to new; the generation increases by one (BR-40…47).
- Reset needs a confirmation stating what is kept and what is lost. When nothing has been studied yet, it says there is nothing to lose (BR-50).
- A study mode unavailable because of the algorithm must be presented as not available for this deck, and must **not** suggest Reset as the way to unlock it (BR-100).

### F13 · Progress overview (UC-12)

**Goal.** See recent effort.

**Data.** Current streak in days · today's cards split into learning and reviewing · the last seven days, oldest to newest, zero-filled · whether any activity ever happened.

**Constraints**
- Counting unit is the card-day; `browse` produces none (BR-192, BR-193).
- Streak: if today has activity, count back from today; if not but yesterday did, the streak is **held** from yesterday; otherwise it is 0. No upper limit (BR-197).
- A card-day is Learning when any answer that day was part of a learning session; otherwise Reviewing. Learning + Reviewing = total (BR-195).
- Read-only; updates live on new answers and at local midnight (BR-190, BR-199).
- Library-wide only; no deck filter (BR-191).

### F14 · Progress by deck (UC-13)

**Goal.** See which decks received attention and which were neglected.

**Data per scope** (library level, or one deck): for the last 7 and 30 days — active cards, active days, learning card-days, reviewing card-days — for the scope itself and for each direct child deck, plus the path of the scope.

**Constraints**
- Exactly two ranges, 7 and 30 days ending today; switching is instant, both come from one read (BR-184).
- Decks sort by active cards in the selected range ↓, then name, then id. Decks without activity stay, last (BR-187).
- History belongs to the card's **current** location: moving a card moves its whole history (BR-185).
- Reset changes no number; permanently deleted cards disappear from every past day; cards in Trash are excluded (BR-198, BR-257).

### F15 · Settings (UC-16)

**Goal.** Set app-wide preferences.

**Actions**
- Study defaults: card limit, new-card order.
- Theme: system, light, dark.
- Language: system, English, Vietnamese.
- Reset app options to defaults, after confirmation.
- Open the daily reminder.

**Constraints**
- Defaults: card limit 20, order `created`, theme `system`, language `system` (unmatched system languages fall back to English).
- Changes apply immediately, without restart or losing the user's place (BR-214, BR-215).
- Each change is saved on its own; a failed save keeps showing the persisted values (BR-216).
- Resetting app options never touches decks, per-deck overrides or learning progress, and its wording must not be confusable with "Reset learning progress" (BR-217).

### F16 · Daily reminder (UC-17)

**Goal.** Get one nudge a day when reviews are waiting.

**Actions**
- Turn the reminder on; on Android 13+ the notification permission is requested only at that moment.
- Choose the time of day (default 20:00, local time).
- Turn it off.
- Open a delivered notification to land on Study home.

**Constraints**
- Off by default; nothing is scheduled or requested before the user turns it on (BR-218).
- At most one notification per local day, and only if overdue + due today > 0 **when it fires**. Unlearned cards never trigger it (BR-220, BR-221).
- Content may name the most urgent root deck, the total due, and the number of other decks. Never card content, tags or history — including on the lock screen (BR-222).
- Permission denied is a recoverable state: the reminder stays off, the user is told how to enable notifications in system settings and can retry (BR-228).
- Where reminders are unsupported (web, iOS today), the feature reports itself unavailable rather than offering a switch that does nothing (BR-229).
- The chosen time stays the same local time across time-zone changes (BR-219).
- Opening the notification never starts a session; dismissing it changes nothing (BR-225).

### F17 · Trash (UC-21)

**Goal.** Recover deleted items, or remove them for good.

**Actions**
- List deletions, newest first, filtered by all / cards / decks. Each shows its name, type, when deleted, days left, original location, and how many decks and cards it contains.
- Restore one item to a chosen target.
- Undo a single deletion right after performing it — back to its original place.
- Select several items of one type and restore or permanently delete them.
- Permanently delete, after a strong confirmation stating the exact count and that study history is lost.

**Constraints**
- Deleting is always a move to Trash; deleting several items creates one recoverable entry per item, and undo is only offered for a single-item deletion (BR-256, BR-263).
- Restore always asks for a target: a card goes to a non-root deck of the same root holding cards or empty; a sub-deck follows the move rules; a root deck can only go back to the top level (BR-261).
- Undo fails with a reason if the original place is no longer valid (BR-263).
- The original location is information only, never a promise of where restore goes (BR-267).
- Retention is 30 × 24 hours; automatic purge runs at app start, on resume and when Trash opens (BR-264).
- A deletion that still contains another, younger deletion cannot be purged yet (BR-265).
- A selection never mixes cards and decks (BR-266).
- Destructive emphasis belongs only to permanent deletion — not to moving to Trash, not to restore (BR-266).
- Trashed content disappears from every other area: library, counts, study, progress, search, tags, move targets, import duplicate checks, export (BR-257).

---

## 5. Business rules

### 5.1 Validation

| Field | Rule |
|---|---|
| Deck name | Not empty after trimming; ≤200 characters |
| Review algorithm | Required when creating a root deck; `eight_box` or `sm2` |
| Card front | Not empty after trimming; ≤60 characters |
| Card back | Not empty after trimming; ≤240 characters |
| Card example / hint / pronunciation | Optional; ≤240 characters each; an empty value is stored as absent |
| Tag name | Not empty after trimming; ≤50 characters; no control characters; unique ignoring letter case (Unicode-aware, accents kept) |
| Tags per card | ≤10 |
| Deck depth | ≤10 levels, root = 1 |
| Card limit per session | Integer 1–200; default 20 |
| Reminder time | Minute of day 0–1439, local time; default 1200 (20:00) |
| Import encoding | UTF-8, with or without BOM |

### 5.2 Deck tree

- A root deck is created with content type `deck` and keeps it forever (BR-58).
- A new sub-deck starts `unset`. Its first child — card or deck — sets the type, in the same write (BR-60, BR-62).
- When the last active direct child is deleted, moved away or sent to Trash, the deck returns to `unset` in the same write (BR-163, BR-260).
- A deck never holds cards and sub-decks at once (BR-65). The tree has no cycles (BR-69).
- Every deck knows its root directly; moving a subtree re-points its whole subtree (BR-56, BR-71).
- Manual order exists only among siblings with the same parent (BR-268).

### 5.3 Review algorithms

**`eight_box`** (BR-15, BR-16)

| Answer | Box change |
|---|---|
| `forgotten` | back to box 1 |
| `remembered` | one box up, at most box 8 |

| Box | 1 | 2 | 3 | 4 | 5 | 6 | 7 | 8 |
|---|---|---|---|---|---|---|---|---|
| Interval (days) | 1 | 2 | 4 | 8 | 16 | 32 | 64 | 128 |

Box 8 is not an exit; a remembered box-8 card is rescheduled 128 days later.

**`sm2`** (BR-17…19): actions map to quality `again`=0, `hard`=3, `good`=4,
`easy`=5. The ease factor is updated before the interval is multiplied and never
drops below 1.3.

**Both**: a next due date lands on **local midnight** of day N, stored in UTC
(BR-105). A card finishing learning starts at box 1 / interval 1, due at the
start of the next local day (BR-144).

### 5.4 Card state and counts (derived, never stored)

| Label | `eight_box` | `sm2` |
|---|---|---|
| `new` | not learned yet | not learned yet |
| `beginning` | box 1–3 | interval < 8 days |
| `reviewing` | box 4–7 | interval 8–127 days |
| `mastered` | box 8 | interval ≥ 128 days |

The labels are readings, not a state machine: a lapse can move a card from
`reviewing` back to `beginning` (BR-88…91).

| Set | Definition | Notes |
|---|---|---|
| New | not learned | Never merged with Due into one number (BR-150) |
| Due | learned and due time ≤ now | = Overdue + Due today |
| Overdue | learned and due before start of local today | Carries "overdue for N days" = local day boundaries passed since the oldest due card (BR-161) |
| Due today | learned and due since start of local today, ≤ now | |
| Scheduled | learned and due time > now | Resting cards; not a warning (BR-162) |

New + Due + Scheduled = total. The deck schedule status is `notDue` when nothing
is due, `dueToday` when the oldest due card is from today, `overdue` otherwise.
All of it re-evaluates at local midnight without any write (BR-161).

### 5.5 Study

Covered in F10. Also: study history is append-only — never edited, never
deleted by reset; only permanent deletion of its card removes it (BR-43).
Labels shown on screen are never stored; only canonical actions are (BR-132).

### 5.6 Generation and locking

- Every root deck has a generation, starting at 1 (BR-40).
- Card schedules, sessions and history rows all carry the generation they belong to (BR-45).
- A write from an older generation is rejected (BR-46, BR-84).
- One tree has exactly one active algorithm and one generation of card schedules at a time (BR-48, BR-49).

### 5.7 Time

- Instants are stored in UTC. Day-based logic (due dates, overdue, streak, progress windows, reminder) uses the **local** day at the moment of reading (BR-105, BR-192).
- The reminder time of day is local and is never converted to UTC (BR-219).

### 5.8 Privacy

- Card content, notes, history, imports, exports and trash contents are private (BR-51).
- Content is never logged at any level (BR-52).
- Export and backup happen only on explicit user request (BR-54).
- Reminder notifications never contain card content (BR-222).

---

## 6. Entity lifecycles and states

### 6.1 Deck content type (BR-163)

| State | Meaning |
|---|---|
| `unset` | Empty sub-deck; accepts a card or a sub-deck as first child |
| `card` | Holds only cards |
| `deck` | Holds only sub-decks. Root decks are always `deck` |

| From | To | Trigger |
|---|---|---|
| `unset` | `card` | First card created, moved in, imported or restored into it |
| `unset` | `deck` | First sub-deck created, moved in or restored into it |
| `card` | `unset` | Last active card deleted, moved away or trashed |
| `deck` | `unset` | Last active sub-deck deleted, moved away or trashed |

Not allowed: `card` ↔ `deck` directly; any manual change; any change to a root.

### 6.2 Algorithm lock and generation (root deck)

| State | Condition | Allowed |
|---|---|---|
| Unlocked | No card of the current generation has finished learning | Change algorithm freely; Reset |
| Locked | A card of the current generation has finished learning | Reset only |

| From | To | Trigger |
|---|---|---|
| Unlocked | Locked | First card finishes its learning sequence (BR-13) |
| Locked | Unlocked | Reset learning progress; generation +1 (BR-44) |
| Unlocked | Unlocked | Algorithm changed; generation unchanged (BR-12) |

### 6.3 Card schedule

| State | Condition |
|---|---|
| New | Not learned; no due time |
| Scheduled | Learned; due time in the future |
| Due today | Learned; due since the start of today |
| Overdue | Learned; due before today |

| From | To | Trigger |
|---|---|---|
| New | Scheduled | Finishes the learning sequence |
| Scheduled | Due | Time passes the due time |
| Due | Scheduled | A `scheduled` review answer |
| Any | New | Reset learning progress |

Editing content never changes it (BR-10). A `relearning` answer never changes it (BR-78).

### 6.4 Card flag

`off` → `on` by the user, or automatically when a card hits the `self_assess`
repeat cap. `on` → `off` only by the user (BR-92, BR-104). Reset keeps it.

### 6.5 Study session

| Status | End reason | Meaning |
|---|---|---|
| `in_progress` | — | Open |
| `completed` | — | Every card finished |
| `abandoned` | `user_exit` | The user left, or chose to start something new instead of resuming |
| `abandoned` | `interrupted` | The OS closed the app and the session was not resumed the same day |
| `invalidated` | `scheduler_reset` | The deck was reset while the session was open |
| `invalidated` | `scheduler_changed` | The algorithm was changed while the session was open |
| `invalidated` | `stale_generation` | The session tried to write after a reset |
| `invalidated` | `content_deleted` | Its deck or one of its cards went to Trash |
| `failed` | `persistence_error` | An answer could not be saved and the session could not continue |

`in_progress` moves to exactly one of the other statuses, and every one of them
is terminal. Answers saved before an abnormal end are always kept (BR-86).

**Session kind:** `learning` or `reviewing`, stored, never both.

**Stage progression (learning):** the session's current stage advances along the
algorithm's sequence, skipping stages no card can take; the session completes
after the last stage.

**Queue item** (per card, per stage, per round): `pending` → `completed`.

### 6.6 Trash batch (AD-22)

| From | To | Trigger |
|---|---|---|
| Active item | In Trash | User deletes a card or deck (with its active descendants) |
| In Trash | Active | Restore to a chosen target, or undo to the original place |
| In Trash | Gone | Permanent delete by the user, or automatic purge ≥30 days after deletion |

A descendant already in Trash from an earlier deletion stays in its own entry
and is not restored with the later one (BR-258).

### 6.7 Tag

| From | To | Trigger |
|---|---|---|
| — | Exists | Added to a card by a new name, or created by import |
| Exists | Renamed | Rename to a name no other tag has (same id, same cards) |
| Exists | Merged away | Rename to another tag's name: its cards move to that tag, this tag disappears |
| Exists | Gone | Deleted: removed from all cards, cards untouched |

A tag with zero cards still exists until deleted (BR-230).

### 6.8 Daily reminder

| State | Meaning |
|---|---|
| Unavailable | The platform cannot deliver reminders |
| Off | Default |
| Permission denied | The user turned it on, the OS refused; stays off, recoverable |
| On | A daily delivery is scheduled at the chosen local time |

Transitions: Off → On (turn on, permission granted) · Off → Permission denied
(turn on, refused) · Permission denied → On (retry after allowing in system
settings) · On → On (time changed) · On → Off (turn off).

Permission is tracked as `notRequested` / `granted` / `denied`.

### 6.9 Import flow

`source` → `parsing` → `preview` → `confirm` → `submitting` → one outcome:
`completed` · `completedWithSkips` (some rows invalid or duplicates skipped) ·
`noCardsAdded` · `commitFailure`.

### 6.10 Starter template install

Outcome is `installed` or `alreadyPresent`.

---

## 7. User-relevant, derived and internal data

| Data | Class | Notes |
|---|---|---|
| Deck name, tree position, manual order, content type | USER-RELEVANT | |
| Root deck algorithm, generation, locked/unlocked | USER-RELEVANT | Locked/unlocked is derived from an internal timestamp |
| Deck created / updated time | USER-RELEVANT | Created time drives "date added" sort |
| Per-root study options override | USER-RELEVANT | Absent means "follow app defaults" |
| Card front, back, example, hint, pronunciation, flag, tags | USER-RELEVANT | |
| Card learned / due / last answered time, answer and lapse counts | USER-RELEVANT | |
| Box (`eight_box`), ease factor, interval, repetitions (`sm2`) | USER-RELEVANT, technical | Shown in card detail and history |
| Review history events | USER-RELEVANT | Append-only |
| Session status, end reason, kind, current mode | USER-RELEVANT | Summary and resume |
| Trash deletion time, days left, contents | USER-RELEVANT | |
| App settings, reminder on/off and time | USER-RELEVANT | |
| Card display state, due/overdue counts, mastered count, schedule status, overdue days | DERIVED | Computed at read time |
| Streak, card-days, active cards, active days | DERIVED | From history |
| Search rank, deck paths | DERIVED | |
| Trash days left, expiry | DERIVED | From deletion time |
| Ids (UUID) | INTERNAL | Needed for actions, never displayed |
| Case-folded copies of front, back, tag name | INTERNAL | Search and uniqueness |
| Denormalised root id, algorithm copies on card schedules and history | INTERNAL | Integrity |
| Algorithm version, per-deck algorithm config | INTERNAL | Config column has no reader today |
| Owner id | INTERNAL | Always empty; reserved for future accounts |
| Source template id / version on a copied deck | INTERNAL | Used only to detect "already added" |
| Session cursor, queue positions, availability markers | INTERNAL | Queue mechanics |
| Recall remaining time, revealed flag | INTERNAL | Lets a recall turn resume exactly |
| Fill comparison version | INTERNAL | Grading policy version |
| Reminder last delivered time | INTERNAL | Prevents a second notification the same day |

---

## 8. Unknowns and inconsistencies

| # | Topic | Status |
|---|---|---|
| U1 | `fill` accepts only cards with an `example`, yet the prompt is the meaning and the example is not part of the question. The requirement is a leftover from when the example sentence was the prompt | **UNKNOWN** — confirm whether `fill` should still require an example |
| U2 | Direction options and `fill` assume the front is a Korean term, while starter fixtures include English-front decks | **UNKNOWN** — confirm how direction wording should read for non-Korean decks |
| U3 | Production starter content does not exist; current templates are fixtures pending a licensed source | **UNKNOWN** — design with placeholder content and the fixture notice |
| U4 | The study entry for a deck exposes new and due counts but not "when the next card becomes due"; that instant exists on Library and Study home data | **DERIVED** — a design that shows next-due inside the deck study entry needs a contract addition |
| U5 | User-facing copy uses "Study mode" for the review algorithm | Copy decision, open to design |
| U6 | Per-deck algorithm config is stored but unused | INTERNAL; ignore |
| U7 | At extraction time several repository documents were behind the code (Settings called a placeholder; Study called unbuilt; five session end reasons where seven exist; the algorithm lock placed at the first review instead of the first learned card). This handoff followed the code; the documents were corrected afterwards in M100.95 | Resolved |

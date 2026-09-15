# MemoX — Feature and Screen Requirements

| | |
|---|---|
| **Status** | draft |
| **Purpose** | Handoff for Claude Design — for each product area, the problem it solves: goal, information, actions, states, constraints |
| **Scope** | Functional requirements per product area at base commit `de1e862c`. Out of scope, on purpose: how any area looks, how information is arranged, which components or interaction patterns represent it |
| **Source of truth for** | — (derived snapshot; `docs/` and `lib/` remain the sources and win on any disagreement) |
| **Depends on** | `PRODUCT_CONTEXT.md` (concepts and rules), `API_CONTRACT.md` (contract names used below) |
| **Updated by task** | claude-design-handoff (no WBS id) |
| **Last updated** | 2026-09-16 |

## How to use this file

- Each section is a **product area**, not a screen. An area may become one
  screen, several, a step inside another, or be merged with a neighbour. That
  is a design decision.
- **Required information** is what a user needs available to reach the goal.
  **Optional information** exists in the data and may help. Neither says where
  or how to show it.
- Names in `code` are contracts or fields from `API_CONTRACT.md`.
- **must** marks a rule taken from the source. Everything else is description.
- Rule IDs (BR-xx) are for traceability only.

---

## 0. Requirements that apply everywhere

**Product structure**
- Four top-level areas exist: **Library**, **Study**, **Progress**, **Settings**. The app opens into Library. The repository's current decision (AD-19) fixes exactly these four in this order; how a user moves between them is open.
- There is no account, profile, login, onboarding flow or network state to design.

**Data behaviour**
- All data is local. Reads are fast and **live**: every list, count and summary updates by itself when the underlying data changes — after an answer, a move, a delete, an import — and at local midnight, without the user refreshing.
- Loading happens only on first read of an area; an error means a local read or write failed and can be retried.
- Failures come in four kinds, and a design must be able to tell them apart:
  - **Validation** — a field is wrong (empty, too long). Belongs to that field.
  - **Refusal / conflict** — a rule prevented the action (e.g. a deck that holds cards cannot receive a sub-deck). Has a specific, explainable reason.
  - **Not found** — the item disappeared, for example deleted from another area.
  - **Failure** — the read or write failed; retryable.
- User-facing messages must never expose SQL, file paths, ids or stack traces (BR-53, BR-245).

**Content**
- UI languages: English and Vietnamese. Card content may be in any script — Hangul, Vietnamese with diacritics, Latin, Chinese, Japanese — often mixed in one card.
- Text limits: deck name 200, card front 60, card back 240, example / hint / pronunciation 240 each, tag name 50, 10 tags per card.
- Long content must remain fully readable; it must not be cut off arbitrarily (BR-240).
- Counts range from 0 to tens of thousands.

**Appearance and access**
- The user chooses light, dark or system appearance, so every area needs both appearances.
- Meaning must not rely on colour alone — schedule state, history generations, question direction (BR-204, BR-243).
- The repository's definition of done checks small screens and large system text sizes.
- All times are shown in the user's local time; "today" is the local day.

**Destructive actions**
- Moving something to Trash is recoverable and is not a destructive action.
- Only permanent deletion from Trash is destructive (BR-266).

---

## A1 · Library — deck tree

Top level (root decks) and inside any deck that holds sub-decks. A deck that
holds cards leads to **A8**; an empty deck (`unset`) is a state of this area.

**User goal**
- Understand which decks exist and where work is waiting.
- Decide what to open, study, create or reorganise.

**Required information**
- Per deck: name, whether it holds cards or sub-decks or is empty, new card count, due card count (with overdue and due-today split), schedule status (`notDue` / `dueToday` / `overdue`) and number of overdue days (`DeckSummary`).
- New and due as **two separate numbers** — never merged into one (BR-150).
- Where the user is in the tree, from the root down (`ancestors`).
- Inside a deck: the level's own totals — overdue, due today, new, scheduled — which add up to the level's card total (BR-162).

**Optional information**
- Total cards, mastered count and mastered fraction (`learnedCardCount`, `learnedFraction`), fully-mastered flag, sub-deck count.
- Review algorithm of the tree (inherited from the root).
- When the next card becomes due (`nextDueAt`), for a calm "nothing due" state.
- Deck created time (drives "date added" sort).

**Available actions**
- Open a deck (its sub-decks, or its cards).
- Filter: all decks / only decks with due cards.
- Sort: manual, date added, name, most due cards, progress.
- Create a root deck (top level) · create a sub-deck (in a deck that holds sub-decks or is empty) · create a card (in a deck that holds cards or is empty).
- Rename, move, reorder, delete a deck (**A2**–**A4**).
- Change review algorithm, reset learning progress (**A5**, root decks).
- Study a deck (**A16**) and set its study options (**A17**).
- Go to starter library (**A6**), search (**A7**), tag catalog (**A13**), Trash (**A14**).
- Import cards into an empty or card-holding deck (**A11**).

**Possible states**
- Loading (first read).
- Top level, no decks at all — a first-launch state; the starter library and root-deck creation are the ways forward.
- Top level with decks.
- Inside a deck holding sub-decks.
- Inside an empty sub-deck (`unset`) — can receive either a sub-deck or a card.
- Filter "due" active with no matching deck ("nothing due right now").
- Every deck at zero workload — normal, not an error.
- Deck not found (deleted elsewhere while open).
- Read error, retryable.

**Business constraints**
- A root deck holds only sub-decks: creating a card is not offered at top level or inside a root (BR-58, BR-59).
- Inside a sub-deck holding cards, only card creation applies; holding sub-decks, only sub-deck creation (BR-66). Empty offers both (BR-61).
- Scheduled cards are resting, not a warning (BR-162).
- Status and overdue days refresh at local midnight with no user action (BR-161).
- Maximum depth 10 (BR-55).

**Related entities**: Deck, DeckSummary, DeckListSnapshot.

---

## A2 · Deck create and rename

**User goal**
- Create a root deck or a sub-deck; fix a deck's name.

**Required information**
- For a new root deck: the two review algorithms to choose from, with enough explanation to choose (`eight_box`: moves cards through eight boxes, forgiving of long breaks; `sm2`: intervals adapt to how well each card is recalled), and the fact that the choice locks after the first card finishes learning.
- For a sub-deck: which deck it goes into.

**Optional information**
- The current name when renaming.

**Available actions**
- Create root deck — name and algorithm, both required.
- Create sub-deck — name.
- Rename — name.
- Cancel.

**Possible states**
- Editing · submitting · name empty · name too long · algorithm not chosen · parent now holds cards · parent at maximum depth · saved · write failure.

**Business constraints**
- Name not empty after trimming, ≤200 characters.
- No silent default algorithm (BR-11).
- A sub-deck cannot be created under a deck that holds cards, or below level 10 (BR-55, BR-63).

**Related entities**: Deck.

---

## A3 · Deck move and reorder

**User goal**
- Put a sub-deck under a different deck; change the order of sibling decks.

**Required information**
- Candidate targets with their position in the tree (depth), whether each is eligible and, if not, why (`DeckMoveTarget.rejection`).
- For reorder: the siblings and the current manual order.

**Optional information**
- The target's tree (root) and name path.

**Available actions**
- Move a sub-deck under an eligible target.
- Place a deck before or after a sibling.
- Cancel.

**Possible states**
- Targets loading · targets available · no eligible target · moving · moved · refused (rule changed since the list was read) · write failure.

**Business constraints**
- Root decks cannot be moved; a list of targets for a root is empty (BR-70).
- Rejection reasons: the source is a root · the target is the deck itself · the target is its descendant · the target holds cards · different review algorithm · different generation · would exceed depth 10 · already the parent (BR-55, BR-70, BR-74).
- Moving never converts schedules between algorithms (BR-73).
- Reorder only among siblings, only meaningful in manual order (BR-268).
- A move that empties the old parent returns it to `unset` (BR-163).

**Related entities**: Deck, DeckMoveTarget.

---

## A4 · Deck delete and undo

**User goal**
- Remove a deck, knowing what goes with it; recover if it was a mistake.

**Required information**
- How many descendant decks and cards will go to Trash with it (`DeckDeletionImpact`).
- That the deck goes to Trash and is recoverable for 30 days — not permanently deleted.

**Available actions**
- Confirm moving to Trash · cancel · undo immediately after.

**Possible states**
- Impact loading · confirming · moving · moved (undo available) · undone · undo refused (the original place is no longer valid) · write failure.

**Business constraints**
- The deck and all its active descendants go together as one Trash entry (BR-258).
- Any open study session on that material ends as invalidated (BR-259).
- Moving to Trash is not a destructive action (BR-266).
- Undo returns everything to its original place without asking (BR-263).

**Related entities**: Deck, TrashBatch.

---

## A5 · Review algorithm and reset (root deck)

**User goal**
- Change the review algorithm while it is still possible; start a deck's learning over.

**Required information**
- The current algorithm and whether it is locked (`firstAnsweredAt` present = locked).
- For reset: what is **kept** (every deck, sub-deck, card, tag and note, and past review history) and what is **lost** (every card's schedule, due date and progress, and any open session; all cards become new) (BR-50).
- Whether anything has been studied yet — if not, there is nothing to lose.
- For a change while unlocked: that an open study session will be closed.

**Available actions**
- Change algorithm (unlocked only).
- Reset learning progress, choosing the algorithm for the new cycle (same or other).
- Cancel.

**Possible states**
- Unlocked · locked · confirming · applying · applied · refused (not a root / now locked / unknown algorithm) · write failure.

**Business constraints**
- Only root decks own the algorithm (BR-06).
- Locked after the first card of the generation finishes learning (BR-13).
- Choosing the current algorithm changes nothing (BR-12).
- Reset increments the generation; history stays and is labelled by generation (BR-40, BR-43).
- Nowhere else in the app may Reset be suggested as a way to unlock a study mode (BR-100).

**Related entities**: Deck (root), CardStudyState, StudySession.

---

## A6 · Starter library

**User goal**
- Get a ready-made deck into the library and start studying immediately.

**Required information**
- Available templates: title, content language, card count, content source (`DeckTemplate`).
- Which templates are already in the library (`GetInstalledTemplateKeys`).
- A notice that these decks are practice fixtures for development and testing, not published course content (BR-87).
- For adding: the review algorithm to use, with the template's suggestion pre-chosen.

**Optional information**
- The template's deck structure (sub-decks and their cards).

**Available actions**
- Add a template to the library (with algorithm).
- Add a second copy of a template already present, after confirming.
- Leave.

**Possible states**
- Loading · list available · no templates published in this build · adding · added · already present (nothing copied) · add failed (nothing copied) · load failed.

**Business constraints**
- A copy is an ordinary deck, independent of the template; later template versions never touch it (BR-35, BR-36).
- Adding the same template again copies nothing unless the user explicitly asks for a second copy (BR-37, BR-38).
- A copy is all-or-nothing (BR-39).

**Related entities**: DeckTemplate, Deck.

---

## A7 · Library search

**User goal**
- Find a deck, card or tag anywhere, and go to it.

**Required information**
- Deck results: deck name and where it sits (deck path).
- Card results: front, back, and the deck path of the card.
- Card results matched through a tag: that tag's name.
- Results grouped: all decks first, then cards (BR-251).

**Optional information**
- Match quality (exact / prefix / contains) — already expressed by the order.
- Whether a deck result holds cards.

**Available actions**
- Type and clear a query.
- Load more results.
- Open a deck result (to that deck) or a card result (to its read-only detail, never the editor) (BR-254).

**Possible states**
- Initial (nothing typed) · waiting for typing to settle · searching · results · no results · more loading · loading more failed · search failed.

**Business constraints**
- Fields searched: deck name, card front, card back, tag name — nothing else (BR-247).
- Case-insensitive, accent-sensitive (BR-248).
- A card appears once, however many fields matched (BR-252).
- Results and their paths update live after renames, moves and deletes (BR-254).
- Search never writes and never starts studying.

**Related entities**: DeckSearchHit, CardSearchHit.

---

## A8 · Card list of a deck

**User goal**
- See, find and maintain the cards of one deck; act on many at once.

**Required information**
- Per card: front, back, display state (`new` / `beginning` / `reviewing` / `mastered`), flag, tags, and when it is due (`CardListItem`, `dueBadge`).
- Deck name and its path in the tree (`DeckContext`).
- The count matching the current filter, search and tags (`cardCount`) — for "showing N of M".
- While selecting: how many cards are selected.

**Optional information**
- The deck's state distribution: total, new, beginning, reviewing, mastered (`CardStateDistribution`), e.g. "N of M mastered".
- Example, hint, pronunciation.
- Created time.

**Available actions**
- Filter: All / Due / New / Flagged.
- Search within the deck.
- Filter by one or more tags.
- Sort: newest first / due soonest.
- Load more.
- Create a card (**A9**); open a card's detail (**A10**); edit a card (explicitly, not by default when opening) (BR-246).
- Flag / unflag; move a card to Trash with undo.
- Enter multi-select; select or deselect cards; select all matching; clear selection.
- For a selection: move to another deck; move to Trash; set flag; remove flag; add a tag; export (**A12**).
- Import into this deck (**A11**); export the whole deck (**A12**).

**Possible states**
- Loading · list · deck has no cards (with a way to add or import) · no card matches the filter, search or tags · loading more · selection active · bulk action running · bulk action failed (selection kept) · bulk action done (selection cleared) · move targets: none eligible · deck not found · read error.

**Business constraints**
- "Due" and "New" never overlap (BR-151).
- Tags combine as OR among themselves, AND with the filter and search (BR-231).
- Select all covers the whole matching set, not only the loaded cards (BR-167).
- The selection clears when filter, search, sort, tag set or deck changes, and after a successful action; a failed action keeps it and says what failed (BR-167, BR-232).
- While selecting, touching a card toggles selection and does not open it (BR-246).
- Bulk actions are all-or-nothing (BR-166); setting and removing the flag are two explicit commands, never inferred from the current flag of the first selected card (BR-166).
- Move targets are only sub-decks of the same root, holding cards or empty, not the current deck (BR-165).
- Deleting several cards creates one Trash entry per card and offers no undo (BR-256, BR-263).
- Returning from a card's detail keeps filter, search, sort, loaded range and selection (BR-246).

**Related entities**: Card, CardStudyState, Tag, CardMoveTarget.

---

## A9 · Card editor (create and edit)

**User goal**
- Write a card correctly the first time; correct it later.

**Required information**
- Front and back, with their limits (60 / 240).
- Which deck the card belongs to, and its path.
- On edit: current content, flag and tags.

**Optional information**
- Example, hint, pronunciation (≤240 each).
- Tags already in the library, for reuse.

**Available actions**
- Enter or change front, back, example, hint, pronunciation.
- Save · discard changes (with confirmation when something was typed).
- Flag / remove flag.
- Add a tag by name · remove a tag.
- Move the card to Trash (edit only).

**Possible states**
- New · editing · loading the card · field errors (front empty, front too long, back empty, back too long, example / hint / pronunciation too long) · tag errors (empty, too long, control character, already on card is harmless, 10 tags reached) · saving · saved · deck no longer accepts cards (it now holds sub-decks, or is a root) · card or deck no longer exists · write failure.

**Business constraints**
- Editing content never changes the schedule or the history (BR-10).
- Optional fields left empty are stored as absent, not as empty text.
- Adding a tag whose name matches an existing tag in any letter case reuses that tag (BR-93).
- The first card created in an empty deck makes it a card deck (BR-62).

**Related entities**: Card, Tag.

---

## A10 · Card detail and review history

**User goal**
- Read everything about one card and see how it has been studied.

**Required information**
- Front, back, and each optional field that has a value; absent fields do not appear as empty labels (BR-240).
- Tags and flag.
- Current schedule: display state, due time, learned time, last answered time, answer count, lapse count; box (`eight_box`) or ease factor, interval, repetitions (`sm2`) (`CardDetail`).
- History, newest first, each event with: time, study mode, kind (`learning` / `scheduled` / `relearning`), action, timeout (if any), hint used (if any), schedule before → after for the algorithm that event was recorded under, next due time (`CardHistoryEvent`).
- History grouped by generation, each group identified in text (BR-243).

**Available actions**
- Load more history (50 per page).
- Edit the card (**A9**).
- Leave, back to the list context it came from.

**Possible states**
- Loading · loaded · no history yet (valid, e.g. a new card or one that only finished learning) · loading more history · all history loaded · loading more failed · card not found (deleted elsewhere) · read error.

**Business constraints**
- Viewing is read-only and is not studying (BR-239).
- Events show stored values only; before→after fields of the other algorithm never appear (BR-242).
- History from before a reset stays visible, even if the algorithm changed (BR-243).
- No accuracy, score or streak here (BR-243).

**Related entities**: Card, CardStudyState, CardHistoryEvent, Tag.

---

## A11 · Card import

**User goal**
- Turn a spreadsheet or pasted list into cards in one deck, without duplicates or broken rows.

**Required information**
- Target deck.
- Supported sources: CSV, TSV, XLSX file, or pasted text; UTF-8.
- Columns found and which field each maps to (`front`, `back`, `example`, `hint`, `pronunciation`, `tags`, or none); whether the first row is a header.
- Per row: source row number, front, back, status (`ready`, `invalid`, `duplicateExisting`, `duplicateInFile`, `blank`) and, if invalid, every problem (`CardImportRowPreview`).
- Totals: rows, ready, duplicates, invalid, blank (`CardImportPreview`).
- Result: how many imported and how many duplicates skipped (`CardImportResult`).

**Available actions**
- Choose a file · paste text · replace the source.
- Say whether the first row is a header · change a column's field.
- Include or skip duplicates.
- Import · go back a step · cancel.
- After completion: return to the deck.

**Possible states**
`source` · reading/parsing · file problem (`unsupportedFile`, `invalidEncoding`, `emptySource`, `emptySheet`, `unreadableFile`) · mapping incomplete (front or back not mapped) · `preview` · `confirm` · `submitting` · `completed` · `completedWithSkips` · `noCardsAdded` · `commitFailure` · target deck no longer accepts cards.

**Business constraints**
- Target: a sub-deck that holds cards or is empty, re-checked at the moment of import (BR-168).
- Rows need front and back; validation is exactly the manual-entry validation (BR-169).
- Tags in one cell are separated by `;` (BR-169).
- Duplicates: same case-folded front + back, in this deck or earlier in the same source. Other decks never count (BR-170).
- All or nothing; imported cards are new, with no schedule or history (BR-171).
- Import content is private (BR-173).

**Related entities**: Card, Tag, Deck.

---

## A12 · Card export

**User goal**
- Take cards out of the app as a file, to keep, edit or share elsewhere.

**Required information**
- Scope: the whole deck, or the current selection, with its card count.
- Formats: CSV (default), TSV, XLSX.
- What the file contains: six columns — front, back, example, hint, pronunciation, tags — and nothing else (no schedule, no history).

**Available actions**
- Choose format · export (hands the file to the system share mechanism) · cancel · retry after a failure.

**Possible states**
- Choosing · generating · handed to the system (`shared`) · closed without choosing a destination (`dismissed`, a cancel) · retryable failure (`readFailed`, `encodeFailed`, `sharePlatformError`) · no way to share on this device (`shareUnavailable`) · invalid scope (`emptyScope`, `staleSelection` — a selected card was deleted or moved, `deckMissing`).

**Business constraints**
- "Whole deck" ignores the current filter and search (BR-174).
- A partly stale selection fails as a whole; nothing partial is produced (BR-174).
- Export is read-only and keeps the selection (BR-178).
- Must never say the file was saved; it was handed to the system (BR-181).
- Dismissing the share mechanism is not an error (BR-181).

**Related entities**: Card, Deck.

---

## A13 · Tag catalog

**User goal**
- See every tag, fix spelling, combine duplicates, remove tags that are no longer useful.

**Required information**
- Per tag: name as stored, number of active cards carrying it (0 allowed) (`TagCatalogEntry.cardCount`).
- For delete: how many cards will lose the tag (`linkedCardCount`).
- For a rename onto an existing name: that the two tags will merge.

**Available actions**
- Search tags · rename · delete.

**Possible states**
- Loading · list · no tags yet · no tag matches the search · renaming · renamed · merged · name invalid (empty, too long, control character) · tag no longer exists · deleting · deleted · write failure.

**Business constraints**
- Sorted by case-folded name (BR-230).
- Delete removes the tag from cards and never deletes, hides or changes a card; wording must not suggest cards are lost (BR-235).
- Merge keeps the target's spelling and never exceeds 10 tags per card (BR-234).
- A rename that only changes letter case of the same tag is a normal rename (BR-233).

**Related entities**: Tag.

---

## A14 · Trash

**User goal**
- Get back something deleted by mistake; permanently clear what is really unwanted.

**Required information**
- Per entry: item name, card or deck, when deleted, days left before automatic deletion, original location (information only), and for decks how many decks and cards are inside (`TrashBatch`).
- The 30-day retention rule.
- For restore: eligible targets (`TrashRestoreTarget`: top level, or a deck with its parent name).
- For permanent deletion: the exact number of items and that their study history is lost.

**Available actions**
- Filter: all / cards / decks.
- Restore one entry to a chosen target.
- Select several entries of one type; restore them or permanently delete them.
- Permanently delete one entry.
- Retry after a load failure.

**Possible states**
- Loading · list · Trash empty · no cards in Trash · no decks in Trash · selection active (cards only, or decks only) · choosing a restore target · no valid target right now · restoring · restored · permanently deleting · permanently deleted · refused (`targetNoLongerValid`, `targetLevelMismatch`, `purgeWouldTakeAnotherBatch`, `unknownItemType`, `batchHeightUnknowable`) · load failure.

**Business constraints**
- Restore always asks for a target and writes nothing before confirmation; a root deck's only target is the top level (BR-261).
- The original location must not be presented as where restore will put the item (BR-267).
- A selection never mixes cards and decks (BR-266).
- Permanent deletion needs a strong confirmation naming the count; its default choice is the safe one; destructive emphasis is reserved for it (BR-266).
- An entry at exactly 30 days is purged; purge runs on start, resume and opening Trash (BR-264).
- An entry that still contains a younger entry cannot be purged yet (BR-265).

**Related entities**: TrashBatch, Deck, Card.

---

## A15 · Study home

**User goal**
- Know what to study now, with the least thinking.

**Required information**
- Per root deck: name, overdue count, due-today count, new count, total cards (`StudyHomeDeck`).
- An unfinished session from today, if any: deck name, kind (learning / review) and current study mode (`StudyHome.resume`).

**Optional information**
- Algorithm per deck.
- When the next card becomes due (`nextDueAt`).

**Available actions**
- Resume the unfinished session.
- Open a deck's study entry (**A16**).
- With no decks: go to the starter library.
- With decks but no cards: go to the library.

**Possible states**
- Loading · no root decks (starter library is the way forward) · root decks, none with cards (library is the way forward; no starter prompt; no made-up due numbers) · decks with cards and workload · decks with cards and zero workload everywhere (normal, neither error nor achievement) · with or without a resumable session · read error, retryable.

**Business constraints**
- Only root decks, workload over the whole tree (BR-201).
- Order: overdue ↓, due today ↓, new ↓, name, id; decks without workload stay, last, still openable if they contain cards (BR-201).
- Nothing here writes or starts a session; only an explicit action does (BR-200).
- Every offered action must lead somewhere real (BR-202).
- Opening a reminder notification lands here (BR-225).

**Related entities**: StudyHome, StudyHomeDeck, StudySession.

---

## A16 · Study entry for a deck

**User goal**
- Start the right kind of study for one deck, or continue where I stopped.

**Required information**
- Deck name and algorithm (`StudyDeckContext`).
- New card count and due card count (`StudyEntrySummary`).
- For review on `eight_box`: the four study modes with, for each, how many cards it can take and — when zero — why: needs cards with an example (`fill`), needs five different meanings (`guess`), needs at least two pairs (`match`) (BR-99, BR-154).
- For review on `sm2`: the three question directions — term first, meaning first, mixed (evenly split) — and that the choice cannot change once the session starts (BR-203, BR-207).
- An unfinished session from today for this deck, if any.

**Optional information**
- Effective cards per session and new-card order (**A17**).

**Available actions**
- Learn new cards (when new > 0).
- Review due cards (when due > 0): choose mode (`eight_box`) or direction (`sm2`), then start.
- Continue the unfinished session · or start new learning / review instead (which ends the unfinished one).
- Open study options.
- Leave.

**Possible states**
- Loading · new and due available · only new · only due · nothing to learn and nothing due (normal) · a mode unavailable for content reasons · session from today available · starting · refused (`nothingDueToReview`, `nothingLeftToLearn`, `modeHasNoContent`, `modeNotSupportedByScheduler`) · start failure, retryable.

**Business constraints**
- Review cannot start with nothing due; no early review (BR-145).
- When only one review mode exists (`sm2`), there is no mode choice (BR-146).
- A mode unavailable because of the algorithm must be presented as not available for this deck and must not suggest Reset (BR-100).
- Starting new learning or review while a session from today is open ends that session as abandoned (BR-103).
- Only an explicit start creates a session; showing counts never does (BR-101).

**Related entities**: Deck, StudyEntrySummary, StudyReviewOptions, StudySession.

---

## A17 · Study options (per root deck)

**User goal**
- Make sessions the right size, and choose whether new cards come in creation order or shuffled.

**Required information**
- Effective card limit and new-card order, and whether they come from this deck's override or from the app defaults (`StudyOptions.isRootOverride`).
- That changes apply only to sessions started afterwards (BR-213).

**Available actions**
- Change card limit (1–200) · change new-card order (`created` / `random`) · save · go back to app defaults.

**Possible states**
- Loading · following app defaults · overriding · invalid limit (`notANumber`, `tooSmall`, `tooLarge`) · saving · saved · write failure.

**Business constraints**
- Options live on the root deck; sub-decks use their root's (BR-147).
- "Use app defaults" lives with the deck's options, not in app Settings (BR-212).

**Related entities**: Deck (root), AppSettings.

---

## A18 · Study session

**User goal**
- Get through the cards efficiently, with a clear sense of progress and an honest result for each answer.

**Required information (all modes)**
- The current card's content for the current mode (`StudyTurn.card`).
- Progress through the current stage or round: done, total, round number (`StudyTurn.progress`).
- For a learning session: which stage is running, out of the algorithm's sequence.
- The possible answers, taken from the algorithm — never a fixed set (BR-30).

**Per mode**

| Mode | The user needs | The user does |
|---|---|---|
| `browse` | Front and back together | Move forward; look back at earlier cards of the same round |
| `self_assess` | The prompt, then the answer after revealing it; the question direction for review sessions | Reveal; grade with the algorithm's actions (`again`, `hard`, `good`, `easy`) |
| `match` | Up to 5 terms and their 5 meanings, shuffled | Pair them, starting from either side; wrong pairs stay to retry |
| `guess` | One term and exactly 5 meanings | Pick one; only the first pick counts |
| `recall` | The term and the time left of 20 seconds | Reveal before time runs out, then say remembered or forgot; or run out of time |
| `fill` | The meaning; the hint on request, if the card has one | Type the term; submit |

**Optional information**
- Pronunciation, example and hint where the card has them (the design decides which modes show them, respecting what each mode tests).
- Deck name.

**Available actions**
- Answer the current turn (as per mode).
- Continue after seeing a result where the mode waits for it.
- Retry a turn whose answer failed to save.
- Leave the session at any time.

**Possible states**
- Starting (no card yet) · turn waiting for the user · answer being saved · result shown · save failed (same turn, retry) · moving to the next turn · next stage (learning) · next round (grading modes) · recall: counting down / revealed and self-checking / timed out, waiting to continue · fill: empty submit ignored · session finished (→ **A19**) · session ended because the deck was reset, its algorithm changed, or its content went to Trash · session stopped by a save error.

**Business constraints**
- Answers are saved immediately (BR-25); a result must be shown only after it is saved; a failed save neither shows a result nor advances (BR-157).
- The card being answered stays present while its result is shown and while the next turn loads; a full loading state is only for before the first turn (BR-158).
- `self_assess`: a card graded `again` comes back after at least 3 other cards; after 3 repeats it leaves the session and is flagged (BR-26, BR-104).
- `match`: at most 5 pairs visible at a time; the round counter covers the whole round, not one board (BR-156).
- `guess`: exactly 5 options (BR-121).
- `recall`: 20 seconds of real interaction time, paused in background; revealing leads to a two-choice self-check that advances by itself; running out of time is counted wrong and waits for an explicit continue (BR-128, BR-159, BR-160).
- `fill`: correct means the typed text equals the term, ignoring case and outer spaces but not accents; the typed text is never stored; hint use is recorded and changes nothing; on a wrong answer the correct term is shown (BR-134…138).
- Question direction: the prompt keeps its place; only the content swaps; direction is not conveyed by colour alone (BR-204).
- `browse` records nothing and does not count toward progress (BR-111, BR-193).
- Grading modes repeat wrong cards in further rounds until a round is all correct (BR-115, BR-119).
- Leaving keeps everything already answered (BR-86).
- The app being killed resumes the same day at the same turn; recall resumes with its remaining time (BR-103, BR-133).

**Related entities**: StudySession, StudyTurn, StudyCard, StudyQueueItem, CardStudyState, StudyAnswer.

---

## A19 · Session summary

**User goal**
- Know what the session achieved, and how it ended.

**Required information**
- Session kind; how it ended: finished, left early, stopped because of a reset, an algorithm change, content moved to Trash, or a save error (`StudySessionSummary.status`, `endReason`).
- Cards that finished learning (learning) or were reviewed (review) (`finishedCards`).
- Wrong turns out of total turns (`wrongTurns`, `totalTurns`).

**Optional information**
- Cards answered (`answeredCards`).

**Available actions**
- Return to the deck · go to study home · start another session (subject to **A16** rules).

**Possible states**
- Loading · completed · abandoned (`user_exit`, `interrupted`) · invalidated (`scheduler_reset`, `scheduler_changed`, `stale_generation`, `content_deleted`) · failed (`persistence_error`).

**Business constraints**
- Everything answered before an abnormal end is kept, and the summary must say so where relevant (BR-86).
- A learning session that was left early leaves no schedule for unfinished cards (BR-144).

**Related entities**: StudySession, StudySessionSummary.

---

## A20 · Progress overview

**User goal**
- See whether I am keeping up a habit.

**Required information**
- Current streak in days, and whether it is **held** from yesterday because today has no activity yet (`ProgressOverview.currentStreakDays`, `isStreakHeldFromYesterday`).
- Today: cards studied, split into learning and reviewing.
- Last seven days, oldest to newest, each with total, learning, reviewing; days with nothing show zero.

**Optional information**
- Whether any activity ever happened (`hasLifetimeActivity`) — distinguishes a new user from a lapsed one.

**Available actions**
- None required; it is read-only. Progress by deck (**A21**) belongs to the same top-level area.

**Possible states**
- Loading · never studied · studied today · not yet today but streak held · streak lost (0) · long streak · read error, retryable.
- Updates live after answers, deletions and at local midnight, without falling back to a loading state (BR-199).

**Business constraints**
- One card studied several times in a day counts once (BR-192).
- Must not show accuracy, correct rate, longest streak, goals, XP, points, heatmaps, deck filters, sharing or celebration effects (BR-191).
- Reset does not change these numbers (BR-198).

**Related entities**: ProgressOverview, ProgressActivityDay.

---

## A21 · Progress by deck

**User goal**
- See which decks got attention recently and which were neglected; drill into a deck.

**Required information**
- Range choice: last 7 days / last 30 days.
- For the current scope (library or a deck): active cards, active days, learning card-days, reviewing card-days (`DeckActivitySnapshot.scopeLast7Days`, `scopeLast30Days`).
- For each direct child deck (library: each root deck): name and the same four numbers (`DeckActivity`).
- Where the scope sits in the tree (`scopePath`).

**Available actions**
- Switch range · open a child deck's level · go back up.

**Possible states**
- Loading · library level · deck level · no activity in the range (decks still listed) · a deck without children · deck not found · read error.

**Business constraints**
- Exactly four numbers; nothing else (BR-182).
- Switching range is instant (BR-184).
- Sorted by active cards in the selected range ↓, then name, then id; decks without activity stay, last (BR-187).
- Activity follows the card's current location (BR-185).
- Read-only (BR-188).

**Related entities**: DeckActivitySnapshot, DeckActivity, DeckActivityMetrics.

---

## A22 · Settings

**User goal**
- Make the app look and behave the way I want.

**Required information**
- Current theme (`system`, `light`, `dark`), language (`system`, English, Vietnamese), default card limit, default new-card order (`AppSettings`).
- For study defaults: that they apply to sessions started afterwards, and that decks with their own override keep it (BR-212, BR-213).
- For reset: that decks and learning progress are not affected (BR-217).

**Available actions**
- Change theme · change language · change default card limit · change default new-card order · reset app options (with confirmation) · open daily reminder (**A23**).

**Possible states**
- Loading · loaded · saving one option · saved · invalid card limit · save failed (other options keep their saved values) · resetting · reset done.

**Business constraints**
- Theme and language apply at once, without restart and without losing the user's place (BR-214, BR-215).
- Each option saves independently (BR-216).
- Reset app options must not be confusable with reset learning progress (BR-217).

**Related entities**: AppSettings.

---

## A23 · Daily reminder settings

**User goal**
- Be reminded once a day, at a time that suits me, only when there is something to review.

**Required information**
- On or off; reminder time (local) (`ReminderSettings`).
- Whether reminders are available on this device (`capability`).
- That it only fires when cards are due.
- That the notification may show a deck name and a due count, including on the lock screen (BR-222).

**Available actions**
- Turn on (triggers the system permission request where required) · change time · turn off · after a denial, get guidance to system settings and retry.

**Possible states**
- Loading · unavailable on this device · off · turning on · permission denied (still off, recoverable) · on · changing time · turning off · could not schedule (still off) · could not save (unchanged) · turned off but an earlier notification may still show · load error.

**Business constraints**
- Off by default; permission is asked only after the user turns it on (BR-218, BR-228).
- Unavailable must not look like a working switch (BR-229).
- A stored "on" is never shown unless turning on fully succeeded (BR-228).

**Related entities**: ReminderSettings, ReminderOverview.

---

## A24 · Reminder notification (system surface)

**User goal**
- Be told, briefly and privately, that reviews are waiting.

**Required information**
- Total cards due; the most urgent root deck's name; how many other decks have due cards (`ReminderSummary`).

**Available actions**
- Open → Study home (**A15**). Dismiss → nothing happens.

**Possible states**
- One due deck · several due decks · nothing due (no notification at all).

**Business constraints**
- At most one per local day; replaces the previous day's if still showing (BR-221).
- Never card fronts, backs, examples, hints, pronunciation, tags or history (BR-222).
- Most urgent = overdue ↓, overdue days ↓, due today ↓, name, id (BR-223).
- Opening never starts a session (BR-225).

**Related entities**: ReminderSummary, ReminderWorkload.

---

## Appendix · Rules with user-visible wording consequences

These are settled product rules about what the user must or must not be told.
Wording itself is a design decision.

| Rule | Consequence |
|---|---|
| BR-50 | Reset confirmation states what is kept and what is lost |
| BR-87 | Starter content is described as practice fixtures, not course material |
| BR-100 | An algorithm-blocked study mode never suggests Reset |
| BR-150 | New and due are never merged into one number |
| BR-162 | Resting (scheduled) cards never look like a warning |
| BR-181 | Export never claims the file was saved; dismissing is not an error |
| BR-191 | Progress never shows accuracy, XP, goals, heatmaps or celebrations |
| BR-202 | Zero workload with cards is presented as normal, not as error or achievement |
| BR-213 | Changing study defaults says it affects future sessions only |
| BR-217 | Resetting app options is never worded like resetting learning progress |
| BR-222 | Notifications never contain card content |
| BR-235 | Deleting a tag is worded as removing it from cards, not losing cards |
| BR-256 | Deleting says "moved to Trash", never "deleted permanently" |
| BR-266 | Only permanent deletion carries destructive emphasis |
| BR-267 | A trashed item's original location is information, not a restore promise |

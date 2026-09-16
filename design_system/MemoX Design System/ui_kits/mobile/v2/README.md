# MemoX — Screens v2 (product-truth redesign)

`index.html` is a click-through wall of the MemoX product screens, rebuilt from
the handoff in `docs/claude-design/` rather than from the current app. Every
screen shows as a **Light (Tokyo Pure) / Dark (Tokyo Nebula)** pair with a state
stepper; the header switches theme, **copy language (EN / VI)** and stage
background. Card content is never translated — only chrome is.

The v1 kit in `../` is untouched, for comparison.

- **Functional source of truth:** `PRODUCT_CONTEXT.md`, `FEATURE_SCREEN_REQUIREMENTS.md`, `API_CONTRACT.md`, `SAMPLE_DATA.json`.
- **Visual source of truth:** the existing MemoX kit — `colors_and_type.css` tokens, `components.css` contracts (`.card`, `.pill-btn`, `.icon-btn`, `.appbar`, `.fab`, `.bottom-nav`), and the shared primitives in `../screens/_shared.jsx`.
- No global token, type, spacing, radius or icon scale was changed.

## Files

```text
index.html            gallery harness (theme / language / stage toggles, state steppers)
_kit.jsx              v2 shared kit — 4-area nav, EN/VI copy switch, count vocabulary,
                      deck glyphs, path bar, notes, sheets, confirm dialogs, snackbar,
                      plus a batched <Ic> (one lucide pass per microtask, not per icon)
data.jsx              sample data shaped like API_CONTRACT.md, taken from SAMPLE_DATA.json
theme-scope.css       .memox-dark scope, extracted verbatim from ../index.html
screens/*.jsx         one file per product area; each takes a `state` prop
```

## Screens and states

| # | Screen | States |
|---|---|---|
| A1 | Deck tree | top level · loading · first launch · inside a deck · empty sub-deck · zero workload · due filter with no match · level 10 · deck actions · sort & filter · deck not found · read error |
| A2–A4 | Deck create / rename / move / reorder / delete | new deck · schedule not chosen · name empty · name too long · creating · new sub-deck · parent holds cards · at level 10 · rename · move targets · move refused · root has no targets · reorder · delete impact · deleting · moved to Trash + undo · undo refused |
| A5 | Review schedule + reset | locked · unlocked · switching · switched · just locked · switch failed · reset confirm · resetting · reset done · nothing to lose |
| A6 | Starter decks | templates · choose schedule · adding · added · second copy · already present · add failed · loading · none in this build · load failed |
| A7 | Library search | results · nothing typed · waiting for typing · searching · no results (accents) · loading more · load more failed · search failed |
| A8 | Card list of a deck | loaded · loading · deck has no cards · searching · no match · loading more · selection · bulk running · bulk failed (selection kept) · bulk done · card trashed + undo · card actions · deck actions · no move target · deck not found · read error |
| A9 | Card editor | new · ready to save · details open · editing · front too long · back empty · 10 tags reached · saving · saved · save failed · deck rejects cards · discard · card gone · loading |
| A10 | Card detail + history | loaded · all history loaded · no history · loading more · load more failed · loading · card not found |
| A11 | Card import | source · reading · not UTF-8 · unsupported file · empty sheet · columns mapped · back not mapped · preview (duplicates in / skipped) · importing · imported · imported with skips · nothing added · failed · deck rejects cards |
| A12 | Card export | whole deck · selection · preparing · handed over · share closed · failed · no share target · stale selection · nothing to export |
| A13 | Tag catalog | catalog · tag actions · rename · rename→merge · name too long · delete · deleted · merged · row busy · rename failed · tag gone · no match · no tags · loading · read error |
| A14 | Trash | all entries · cards only · decks only · selection · choose a target · no valid target · restoring · restored · undo refused · delete for good · deleting · deleted · contains a younger entry · empty · loading · read error |
| A15 | Study home | workload · session to resume · nothing due · loading · no decks · decks without cards · read error |
| A16 | Study entry for a deck | SM-2 (new + due) · Eight boxes (mode choice) · only new · nothing to do · open session today · starting · no longer due · start failed · loading |
| A17 | Study options | deck override · following app defaults · invalid limit · saving · saved · save failed · loading |
| A18 | Study session | browse · self-assess prompt / revealed · answer saving · save failed · match board / wrong pair · guess / answered · recall counting / self-check / timed out · fill typing / hint / wrong · starting · ended by a reset |
| A19 | Session summary | review finished · learning finished · 200-card session · left early · interrupted · ended by reset · schedule changed · content trashed · save error · loading |
| A20–A21 | Progress | studied today · 30 days · inside a deck · streak held · streak lost · no activity in range · never studied · loading · read error |
| A22 | Settings | loaded · saving one option · saved · invalid limit · save failed · reset options · options reset · loading |
| A23 | Daily reminder | off · asking permission · on · turned on · changing time · permission denied · could not schedule · off (one may still show) · unavailable · loading |

## Relationship to V1

V2 is V1 refined, not a second design direction. Per screen region:

**Kept from V1** — large-title app bars and the drill-down bar (back · title ·
search · more); the inline SearchField on Library; the tinted "today" strip; the
overline + sort-pill header row; the deck card anatomy (44px tile · name + due
badge · icon/label meta row · 5px mastery bar with `masteryColor()`); the
breadcrumb on deck screens; the deck-summary card (mastery donut · state
distribution bar · four-item legend · one full-width study CTA); the filter-chip
row with counts; the count + sort row; V1's CardRow (status dot · front · back ·
status label + tags · flag + due chip); `StudyTopBar` and the centred context
line; the split study card (term · divider · meaning); V1's result hero and its
footer action bar with caption; Progress's range segmented control, `Card(title
· value · sub · chart)` rhythm, dashed per-chart empty, streak tile pair, row
list and read-only footer; the FAB placement rules (above nav on Library, plain
on drill-downs); sheets and dialogs as V1 drew them; the card editor's Save-pill
app bar, deck-destination chip, Required overline, FieldHeader (label · Required
· count/max), front/back card fields with the inline error line, OptionalField
rows, tag pills + dashed Add tag, and the save bar with its caption; search's
focused in-bar field, type chips with counts, Group (coloured type header ·
count · See all) and 26px-tile Row with query Highlight; the history timeline
(dot marker · kind badge · relative + absolute time · note · box-move meta);
the tag list (28px tile · name · card count · Most-used flame · row ⋮) with its
44px search box and count + sort row; Settings' Section + icon-tile Row
(36px tile, 16px label, 12px subtitle, trailing control) and its closing line.

**Removed from V1** — folders and the archive action (the product nests decks and
deletes to Trash); per-folder seed colour and icon choice, and the folder
description line (no such fields); the ~14 min estimate; accuracy, duration, box
distribution, box changes, tough cards, suspended/buried rows, daily goal and
longest streak; the "All time" range; the Mastered filter chip; share-summary;
the Stats/Home nav destinations (four areas exist, Library first); the editor's
mic/record and speak buttons and the recall % in its history strip; the Folders
result type in search; answer durations and the audio-added event kind in the
history timeline; V2's own `DeckGlyph` tile and count chips, replaced by V1's
tinted tile and meta-dot counts.

**Added to V2** — the overdue count and its day age; the new-card count kept
separate from due; sub-deck vs card content and depth (breadcrumb collapse,
level-10 refusal); review schedule and its lock, plus reset with what is kept
and lost; the five-stage learning strip and the review round counter; the
unavailable-mode reason and capacity; per-deck study options; import mapping and
per-row fates; export column list; tags, Trash and the whole set of loading,
empty, filtered-empty, search-empty, selection, refusal, not-found and error
states.

**Adjusted** — the today strip now states overdue / today / new instead of one
merged number; the deck row shows one badge (due) with overdue and new as quiet
meta items; V1's single-colour day bars now stack learning over reviewing; the
Streak card's second tile is today's count rather than a longest-streak record;
the study CTA reads "Study this deck · N due" because it opens the study entry
rather than starting a session; amber text uses a per-theme ink token for
contrast.

**Reverted from the first V2 pass** — the plain totals box went back to V1's
tinted today strip; the chip-based count vocabulary went back to badge + meta
dots; the thin mastery line on the card list went back to V1's donut + summary
card; my own path bar went back to V1's `Breadcrumb`; the custom session app bar
went back to `StudyTopBar`; centred prompt/answer text went back to V1's split
card; the two-card progress layout went back to V1's Card stack; the bottom nav
was removed from drill-down screens; 800-weight display numbers went back to
V1's 24px stat; `--memox-text-muted` micro-labels went back to
`--memox-on-surface-variant`.

## Product constraints reflected

- Root decks hold only sub-decks; a sub-deck holds cards *or* sub-decks; an empty
  deck accepts either (BR-58…66) — which is why the create action changes per level.
- Depth 10 is the maximum; at level 10 no sub-deck creation is offered (BR-55).
- New and Due are never merged (BR-150); scheduled cards are not a warning (BR-162).
- No early review; nothing due is a normal state, not an error (BR-145, BR-29).
- A root deck's schedule locks when its first card finishes learning (BR-13); only
  Reset opens a new cycle, and Reset states what is kept and what is lost (BR-50).
- An algorithm-blocked mode never suggests Reset (BR-100).
- Study options live on the root deck and affect future sessions only (BR-147, BR-213).
- Answers are saved before a result is shown (BR-25, BR-157); the answered card
  stays on screen while its result shows (BR-158).
- Wrong cards return in later rounds (BR-115, BR-119); `browse` records nothing (BR-111).
- Search covers deck name, card front, card back and tag name only, case-insensitive
  and accent-sensitive (BR-247, BR-248); decks precede cards (BR-251).
- Export is six columns of content, never a backup, and is never called "saved" (BR-175, BR-181).
- Deleting is "moved to Trash" (BR-256); destructive emphasis is reserved for
  permanent deletion (BR-266); a trashed item's original location is information,
  not a restore promise (BR-267).
- Deleting a tag is worded as removing it from cards (BR-235); a rename onto an
  existing name merges and says so first (BR-234).
- Progress shows no accuracy, goal, XP, heatmap or celebration and has exactly two
  ranges (BR-191, BR-184); one card studied once a day counts once (BR-192).
- Reminder permission is requested only when the user turns it on, and notifications
  never carry card content (BR-218, BR-222).
- "Reset app options" is worded so it cannot be read as resetting learning progress (BR-217).

## Assumptions

- **Long names.** Deck names clamp to 3 lines in a list and to 2 lines in an app
  bar; the full name is readable on the deck's own screen. Card front/back clamp
  to 2 lines in the list and are shown in full in card detail.
- **Overdue is amber, not red.** Overdue needs attention but is not an error; red
  is reserved for failures and permanent deletion.
- **Sort and filter share one sheet** per level, with the five sorts and the
  due-only filter; the chip row shows the active pair.
- **Reorder uses up/down buttons plus a grip** — a real drag interaction is not
  mocked.
- **Direction wording** is "Term first / Meaning first / Mixed", which avoids
  assuming the front is Korean (open question U2).
- **`fill` unavailability** is worded "only cards that have an example can be
  filled in" — if U1 is resolved by dropping that requirement, the wording lives
  in one place (`StudyEntry.jsx`).
- **Starter decks** carry the fixture notice as the first thing on the screen (U3).
- Vietnamese copy is a design draft, not reviewed localisation.

## Product gaps noticed (not built into the design by default)

- **Next-due instant in the deck study entry.** A16's "nothing due" state reads
  much better with *when* the next card is due. `nextDueAt` exists on the Library
  and Study-home reads but not on `WatchStudyEntry` (U4). The line is only shown
  in the nothing-to-do state and would need that contract addition.
- **Overdue-days in the study entry.** "Oldest card has been due for N days" uses
  `overdueDayCount`, which `DeckSummary` carries but `StudyEntrySummary` does not.
  Either add it, or drop that line.
- **"Find cards with this tag"** in the tag catalog (A13) has no dedicated
  contract; it is drawn as navigating to library search for the tag name, which
  the search contract does support.
- **Sub-hour expiry in Trash.** "1h left" needs an expiry instant; the contract
  exposes days left. Shown on the entry that is hours from purge — drop it if
  only whole days are available.

## Design-system gaps

These are real primitives the screens needed and the shared kit does not have.
They live in `v2/_kit.jsx` today and should be promoted into
`../screens/_shared.jsx` + `components.css` if this redesign is adopted:

- **Count chip vocabulary** (`CountChip`, `DeckCounts`, `LevelTotals`) — the
  overdue / due-today / new / scheduled distinction is used on 6 screens.
- **Option row** (radio row with title, description and trailing capacity) — used
  by deck create, review schedule, study options, study entry and starter decks.
- **Number stepper** — cards per session, in two different densities.
- **Segmented control** — theme and new-card order in Settings.
- **Snackbar / undo toast** — undo after delete, save results, export handoff.
- **Note / inline rule** — the tone used to state a product rule without alarming.
- **Stacked day-bar chart** — Progress overview.
- A batched icon renderer: the shared `<Ic>` runs a document-wide
  `lucide.createIcons()` per icon instance, which is quadratic on a gallery page.

## Screens removed relative to the v1 kit

Dropped because the product does not have them (PRODUCT_CONTEXT §3 "Not in the product"):

| v1 screen | Why |
|---|---|
| 01 Onboarding (welcome, sign-in, restore, restore failed, import handoff) | No accounts, no login, no backup/restore. A fresh install opens into an empty Library — covered by A1 *First launch* |
| 02 Dashboard (Home tab, daily goal, streak goal, offline banner, multi-resume) | Only four areas exist (Library, Study, Progress, Settings) and the app opens into Library; no goals, no network state |
| 03 Library overview + 04 Folder detail (folders, archive) | There is no folder concept and no archive — decks nest directly, and deleting means Trash |
| 18 Stats (weekly chart + per-deck mastery with goal) | Replaced by A20–A21 Progress, which counts card-days only and shows no goal |
| 20 Settings states *signed out / signing in / sync error*, 21 Account sync (Drive backup, restore, token expiry) | No account and no sync exist |
| 22 Learning settings (daily goal) | No goals; its reminder half survives as A23 |
| 23 Audio & speech (voices, TTS, engine errors) | Cards have no audio |
| 24 Appearance + 25 Language as separate screens | Folded into A22 Settings as a theme segment and a language row |
| `OfflineBanner` primitive | Nothing in the product uses the network |

# MemoX — Mobile UI Kit v3 (V1, corrected from product truth)

`index.html` is a click-through wall of MemoX mobile screens. **V3 is a direct
clone of V1** (`../index.html`, `../screens/`) whose screens were then corrected
against `docs/claude-design/` — `PRODUCT_CONTEXT.md`, `FEATURE_SCREEN_REQUIREMENTS.md`,
`API_CONTRACT.md`, `SAMPLE_DATA.json`. V1 and V2 are untouched.

Every change is one of KEEP · ADD · EDIT · REMOVE; the reason sits in each
screen file's header comment. V2 was not used as a baseline (see "V2 ideas reused").

## Files

```text
index.html          v1 harness (theme toggle, width, state steppers) · GROUPS regenerated from manifest.js
manifest.js         screen order, component names, state ids + labels — edit this, not index.html
screens/_shared.jsx v1 primitives + v3 additions (Snackbar, Note, OptionRow); OfflineBanner and voice search removed
screens/<Name>/<Name>V3.jsx     one screen (window.<Name>V3); the V3 suffix avoids clashing with v1's globals
screens/DeckListScreen/         the recursive deck list — root level AND inside a deck (see below)
screens/<Name>/states/*.jsx     one file per state, registered into window.MemoXStates.<Key>
```

Regenerate `index.html` script tags + GROUPS after adding a screen or state:
read `manifest.js`, list `screens/*/states/*.jsx`, splice both blocks (the gen
script used in this project does exactly that).

## Screens (26)

| # | Screen | From v1 | Product area |
|---|---|---|---|
| 01 | Deck list · recursive | Library overview + Folder detail | A1 top level · A1 inside a deck · A3 · A4 |
| 02 | Review algorithm & reset | — (new) | A5 |
| 03 | Starter decks | — (new) | A6 |
| 04 | Library search | Library search | A7 |
| 05 | Tags | Tag management | A13 |
| 06 | Trash | — (new) | A14 |
| 07 | Card list | Flashcard list | A8 |
| 08–09 | Card create / edit | Flashcard create / edit | A9 |
| 10 | Card detail | Flashcard history | A10 |
| 11 | Card import | Deck import | A11 |
| 12 | Card export | — (new) | A12 |
| 13 | Study home | Dashboard | A15 |
| 14 | Study entry | — (new) | A16 |
| 15 | Study options | — (new) | A17 |
| 16–20 | Browse · Match · Guess · Recall · Fill | Study modes | A18 |
| 21 | Session summary | Study result | A19 |
| 22 | Progress | Progress (+ Stats) | A20 · A21 |
| 23 | Settings | Settings | A22 |
| 24 | Daily reminder | Learning settings | A23 |
| 25–26 | Theme · Language | Appearance · Language | A22 |

Removed v1 screens: Onboarding, Account sync, Audio & speech, Stats (no accounts,
sync, audio; Progress replaces Stats).

## Design-system note

`--memox-warning-ink` (defined in `index.html`, scoped) is the only visual
addition: amber *text* for overdue counts, because `--memox-warning` is a fill
colour and fails contrast as 12px text on light surfaces. No global token changed.
`Snackbar`, `Note`, `OptionRow` in `_shared.jsx` are candidates for promotion into
`components.css` / `components/Mx*.jsx` if v3 is adopted.

## Consistency pass (2026-09-16)

Audit of V3 against V1 + the design kit, fixing repeated patterns at the shared
layer first. No screen concept, flow or palette direction changed.

**Rules this pass made explicit** (apply them to new V3 work):

| Relationship | Rule |
|---|---|
| Single-line text input | `--memox-size-input` (52). Resting fill `--memox-surface-muted`, focused fill `--memox-surface-container-lowest` + 1px primary. The 44px hand-rolled inputs were below the 48dp touch floor. |
| Tinted "hero" surface | Keeps the `.card` ghost edge in both themes. `border: 'none'` on a hero card dissolved it into the page in Light (~1% luminance step). |
| Row title carrying user content (deck / card / tag name) | 2-line clamp, `lineHeight: 1.35` — the shared `ListRow` rule. Single-line ellipsis stays for app-bar titles, filenames, numbers and the import preview table. |
| Small control, 36–40px (stepper button, segment group, compact pill) | `--memox-radius-md`. The invented radius 10 is gone. |
| 20px checkbox | `--memox-radius-xs`. |
| Uppercase micro-label | `.ov` spec: 12px / 700 / 0.6px tracking; colour per site. Was 700·0.3, 600·0.4 and `.ov` in parallel. |
| Title → metadata sub-line | `marginTop: 2`. Was split 1 / 2 across ~50 sites. |
| Stacked-item gap | repeated list items 8 · distinct content cards 12 · major sections 16. The stray 20 is gone. |
| Row → its own full-width control | `marginTop: 12`. |
| Button height | `--memox-size-button` (48); the 44px CTA in the empty-deck state was below the touch floor. |

**Kept as local exceptions:** the dense flashcard-row container (radius 12, ghost
edge) alongside the roomy `.card` deck row (radius 20) — deck and card are
different entities, not a drift; the study-mode footer hint's 0.3px tracking,
which is identical across all five mode screens; `lineHeight` 1.45 / 1.55 for
caption and body copy, inherited from V1 in the same proportions.

**Still duplicated, promotion candidates:** `Stepper` (Settings + Study options)
and the segmented control (Settings + Progress) — values are now identical, the
code is not yet shared. Same list as `Snackbar` / `Note` / `OptionRow`.

## Targeted consistency fix pass (2026-09-16, later same day)

Second pass, narrower than the one above: token drift, one semantic-color
mixup, two long-text gaps and two control-geometry outliers. No concept,
composition, navigation or palette change.

- **Token drift** — every "small tinted icon tile in an action-sheet row" (24
  files: overflow sheets, move-target rows, deck/card action sheets, Trash,
  Tags, Algorithm, Import) hard-coded `borderRadius: 8` instead of the existing
  `--memox-radius-sm` (8) token. Replaced everywhere; no visual change.
- **Semantic color** — Study home's deck list and Study entry's "New" stat +
  "Learn" button painted the new-card count with `--memox-mastery` (the
  mastered/success green). Card list and Card export already used the correct
  `--memox-status-new` (muted blue-gray) for the same count; Study home/entry
  now match. `--memox-mastery` stays on the "all caught up / nothing to do"
  success states, which is a different meaning and was already correct.
- **Long text** — Progress's deck-level app-bar title had the ellipsis CSS but
  no `flex: 1`, so a long deck name had nothing to shrink against and just got
  clipped by `.app`'s overflow with no "…". Card export's backdrop title had no
  truncation at all. Both now match the established title contract (`flex: 1`
  + `minWidth: 0` + ellipsis) used everywhere else a deck name sits in an app bar.
- **Control geometry** — the daily-reminder "permission denied" banner's two
  buttons were 34px/14px padding; every other inline banner action in the kit
  (Algorithm's switch-failed Retry, this same screen's own "couldn't schedule"
  Retry) is 32px/12px. Sized down to match. Tags' row overflow trigger was
  30×30 where Library and Trash's identical row overflow trigger is 28×28;
  sized down to match. The two other 28-vs-30 icon-tile sizes already in the
  kit (move-target rows vs. action-sheet command rows) turned out to be two
  distinct, already-consistent roles — left alone.
- **Starter Library's title/badge/metadata/action row and Card export's card
  preview rows** were reviewed against long titles/fronts/backs and already
  wrap and clamp correctly — left unchanged.

## One recursive deck list (2026-09-16)

`LibraryOverviewScreen` (01) and `DeckDetailScreen` (02) were the same screen
twice: a list of decks at a level, with a sort pill, per-deck ⋮ and a create FAB.
The spec already treats them as one area (A1 top level / A1 inside a deck) and the
data is recursive (deck → sub-decks, depth ≤ 10). They are now
`screens/DeckListScreen/DeckListScreenV3.jsx` with level-prefixed states
(`rootLoaded`, `deckOverflow`, …); `ctx.state` still carries the un-prefixed id,
so the state modules moved across unchanged.

Written once: the row, the list, the section header + sort pill, the create FAB,
the scroll clearance, and loaded / loading (both levels share `states/list.jsx`).

Level-specific — three branches, nothing more:

| | root | inside a deck |
|---|---|---|
| app bar | large "Library" + starter · tags · Trash | back + deck name + ⋮ |
| context | search + today strip (the one bridge to Study) | summary card + "Study this deck" |
| chrome | bottom nav · FAB "New deck" | breadcrumb · FAB "New sub-deck" (none at level 10) |

Two deliberate visual consequences:

- **One row anatomy at every level** — 44px tile · 14px/700 name, 2-line clamp,
  1.35 line-height · 5px mastery bar. Deck detail's smaller 40px/14px variant is
  gone; a single contract that scales to depth 10 beats a root/nested pair that
  only ever fit two levels. Root and nested already read as distinct screens
  through their chrome (large title + search + today strip vs. back + breadcrumb
  + mastery-donut summary card) — the row itself does not need to duplicate that
  signal, and the 2-line clamp is what actually carries long Vietnamese / Korean
  names, not a bigger font.
- **Rows carry structure + one due chip** (`N sub-decks · N cards`). The
  overdue · today · new breakdown belongs to Study home, which orders by it and
  starts the session; Library only manages. The chip keeps the deck sorts and the
  "Due only" filter meaningful. The deck-level summary card still states the full
  level totals (BR-162).

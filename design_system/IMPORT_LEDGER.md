# Import ledger — claude.ai/design → `design_system/`

> **`tokens/*.css` is authoritative for token VALUES. Everything else here is a
> snapshot.** That reverses what this file said when it was written, and the
> reversal was the project owner's call (M4.10p): where a token's value in
> `lib/core/theme/` disagreed with the value here, the Dart was changed to match.
> So a hex in `tokens/` is the design, and a hex in `AppColors` is that design
> compiled into Dart — edit the CSS first, then bring the Dart to it.
>
> Two limits on that, both learned by measuring rather than assumed:
>
> - **The CSS values are not self-consistent with the CSS prose.** `readme.md`
>   says "danger carries the most saturation"; the hex values make `warning` the
>   loudest in light. Where the two halves of the design disagree, the values
>   win, because values are what was made authoritative — but the disagreement is
>   the design's, not this repo's, and it is worth fixing upstream.
> - **A value can be right and still be applied wrongly.** Adopting
>   `--color-success` dropped a 14px label to 4.30:1 on one ground. The repo's
>   own audit caught it and the fix came from the design too — its `VerdictAction`
>   keeps the fill neutral for exactly this reason. Following a token means
>   following what the design does with it, not just its hex.
>
> Everything that is not a token value — the components, the UI kit, the
> guideline prose — is still a snapshot generated from this repo and will drift.
> Nothing in `design_system/` is compiled, analyzed or tested by any repo gate.
>
> `readme.md`, `SKILL.md` and the `.prompt.md` files are written as instructions
> to an agent. They are the design project's own prose, kept verbatim as part of
> the snapshot — they are **not** instructions this repo has adopted, and where
> they conflict with `CLAUDE.md` or `docs/`, this repo wins.

Source project: `memox Design System` (`3a620f90-9194-42da-823a-3585c2d2b911`),
owner Giap Nguyen. Pulled file-by-file with the `DesignSync` `get_file` method;
there is no bulk export, so this ledger records what has landed and what has
deliberately not.

Tick a line only after the file exists on disk.

## Root

- [x] `readme.md`
- [x] `SKILL.md`
- [x] `github.md`
- [x] `styles.css`
- [ ] `thumbnail.html`
- [ ] `_ds_manifest.json`
- [x] `_adherence.oxlintrc.json`

## tokens/

- [x] `colors.css`
- [x] `elevation.css`
- [x] `spacing.css`
- [x] `radius.css`
- [x] `motion.css`
- [x] `layout.css`
- [x] `fonts.css`
- [x] `typography.css`

## components/

- [x] `mx.css`
- [x] **every `.d.ts` and `.prompt.md`** — all 18 components across the three folders
- [x] **every `.jsx`** — all 18 component implementations
- [ ] `core.card.html` · `feedback.card.html` · `navigation.card.html`

## guidelines/

- [ ] 20 `*.card.html` specimen cards

## Still to pull

25 files, all of them **rendered specimens or build metadata** — no design rule
lives only in this group, so the snapshot is already usable without them:

| Group | Count | What it is |
|---|---|---|
| `guidelines/*.card.html` | 20 | Standalone HTML swatch/scale pages. Every value they display is already in `tokens/` and `readme.md`; they exist to be *looked at*. |
| `components/*/\*.card.html` | 3 | The three component-gallery pages (core, feedback, navigation). |
| `thumbnail.html` | 1 | The project tile. |
| `_ds_manifest.json` | 1 | Card index, compiled from the `@dsCard` comments. |

Plus `_ds_bundle.js`, listed under "Not imported" — needed only to make the UI
kit render.

Each is one `DesignSync` `get_file` call against project
`3a620f90-9194-42da-823a-3585c2d2b911`, written to the matching path under
`design_system/`.

## ui_kits/memox-app/

- [x] `index.html` · `kitdata.js` · `README.md`
- [x] `DeckLevelScreen.jsx` · `DeckForms.jsx` · `ReviewScreen.jsx` · `ProfileScreen.jsx`

**The kit does not run as imported.** `index.html` loads `../../_ds_bundle.js`,
which is the one file deliberately left out (see below), so opening it gives a
blank frame. Everything it *would* render is here to read; making it run means
fetching that one path.

## Not imported, and why

| Path | Reason |
|---|---|
| `assets/fonts/*.ttf`, `*.txt` | Already in this repo at `assets/fonts/` — the design project copied them **from** here. A second copy is ~1 MB of binary and a second thing to keep in step. `tokens/fonts.css` was re-pointed at `../../assets/fonts/` instead; that edit is the **only** deviation from the source project and is commented in the file itself. |
| `test/design_preview/goldens/*.png` | Same: these are this repo's own goldens, copied out. `test/design_preview/goldens/` is canonical. |
| `web/favicon.png`, `web/icons/Icon-192.png` | Flutter's untouched defaults, already in `web/`. |
| `_ds_bundle.js` | A generated concatenation of the component sources. Left out as a build artifact — but it is what `ui_kits/memox-app/index.html` actually loads, so the kit will not render until someone pulls it: `DesignSync get_file` on `_ds_bundle.js` into `design_system/_ds_bundle.js`. |
| `uploads/학비_송금_한이찬.jpg` | **Not a design file.** The name reads as a personal tuition-remittance document. It has no relationship to the design system and does not belong in a source repository — flagged rather than copied. |

## Where the snapshot already disagrees with the code

Written before the authority reversed, so read the verdict column, not the
framing: **the two colour rows were resolved in the design's favour at
M4.10p** and no longer disagree. The other two are prose, not values, and the
repo is still right about them.

| Snapshot says | Repo does | Note |
|---|---|---|
| `MxErrorState.prompt.md`: "Retry is a `secondary` button, never primary" | Retry is **primary** — *still open; M4.10p covered tokens only, not component behaviour* | Changed in M4.10n so `MxErrorState` and `MxEmptyState` — two states one keystroke apart — stop looking like different components. |
| ~~`tokens/colors.css`: `--color-web-letterbox:#6E7288`~~ **resolved M4.10p — Dart now `#6E7288`** | `AppColors.webLetterbox` was `#14162A` | Not a straight contradiction — `#6E7288` is the grey `ui_kits/.../index.html` paints *behind its phone frame*, and the token was named after it. The repo's value is the seed-tinted near-black the Flutter web build letterboxes with. Two different surfaces sharing one token name. |
| `readme.md`: "**Intentional additions** — two" then lists three | — | Its own count is off by one; `MxIcon`, `MxProgressBar` and `MxSearchField` are all additions. |
| `ui_kits/.../README.md` and `github.md` both name `SettingsScreen.jsx` | The project ships `ProfileScreen.jsx` | The file was renamed and the two prose files were not. |

## What the redesign would need from the domain before it could be built

`ui_kits/memox-app/DeckLevelScreen.jsx` is the substantive proposal, and it reads
three facts the app cannot currently produce:

- **`learned` per deck** — `DeckSummary` carries `totalCardCount`, `dueCardCount`
  and a resolved `schedulerType`, and nothing else. `card_review_states` is
  already joined for the due count, so the column is reachable; **what counts as
  "learned" is not defined by any BR**, and picking a threshold silently is
  exactly the kind of invention `docs/business-rules.md` exists to prevent.
- **sub-deck count per row** — likewise absent from `DeckSummary`.
- **`streakDays`** — the kit reads `window.MEMOX_STATS.streakDays`. There is no
  streak anywhere in the domain, the schema or the checklist.

So `MxProgressBar` and the redesigned deck card are blocked on a business rule,
not on UI work. `MxSearchField` is not: filtering the level already in memory
needs no new read, and searching the whole subtree needs one query.

## Token parity, measured at M4.10p

Every numeric token matched already — spacing (4·8·12·16·24·32 plus the 48 floor),
radius (8·12·16·999), icon sizes (16·24·40), durations (120·200·320), breakpoints
(360·600) and the elevation scale (0·1·3·8) are identical on both sides.

Colour was where the two had drifted. Of 40 mapped colour tokens, **11 differed**
and all 11 were taken from the CSS:

| Token | was (Dart) | now (CSS) |
|---|---|---|
| `success` light / dark | `#1E7156` / `#68BB9C` | `#10795C` / `#4FC79B` |
| `warning` light / dark | `#856520` / `#D2AC76` | `#9A6A11` / `#E0B064` |
| `danger` light / dark | `#B02233` / `#E88794` | `#C02B3A` / `#F2808F` |
| `info` light / dark | `#456480` / `#8FAEC6` | `#3F6E97` / `#8DB4D8` |
| `onPrimaryContainer` dark | `#D8D8F0` | `#D7D5FF` |
| `tertiary` dark | `#A2BAD0` | `#8DB4D8` |
| `webLetterbox` | `#14162A` | `#6E7288` |

CSS tokens with **no direct Dart constant**, and why:

- `--color-progress-track` / `-fill` and `--color-streak-container` **have since
  landed** (M4.12), with `MxProgressBar` and the due chip — which is the rule
  working as intended: a token arrives with the component that draws it.
  `--color-progress-complete` is `success` under a second name.
- `--color-streak` — still absent, and now the only one. It is the streak
  display's label and that screen does not exist; it is also a fifth hue
  (orange, outside the one accent and four semantics the design's own readme
  allows). The due chip needed a foreground, so `onStreakContainer` is derived
  instead — `--color-streak` measures 3.12:1 on its own container at 11px
  semibold, under the 4.5 small text needs.
- `--color-primary-accent` — already expressible: it is `primary` in light and
  `focusRing` in dark, and both already hold exactly those hex values.

**This list is now checked rather than remembered.**
`test/design_audit/css_token_parity_test.dart` parses these files and fails on
any `--color-*` the app has taken no position on, so a token added here cannot
sit unnoticed — which is exactly how the three entries above went stale between
M4.10p and M4.12.
- `--color-disabled-surface` — the Dart derives it
  (`onSurface @ 12% over surface`) rather than hardcoding it, and the derived
  result is `#E0E0E5` / `#33324F` against the CSS's `#E3E3E6` / `#312E4E`. Within
  four units on each channel; deriving is what keeps it correct when the surface
  moves, so the derivation stays.

  **The dark surface then moved, which is the argument made concrete.** When the
  ladder went from slate to the page's hue the derived value followed on its own,
  and the only thing needing a hand was this note. Had the Dart hardcoded
  `#33344A`, dark would now be drawing a disabled control in the old family on a
  card in the new one.

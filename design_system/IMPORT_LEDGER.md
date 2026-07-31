# Import ledger — claude.ai/design → `design_system/`

> **This directory is a snapshot, not a source of truth.** `lib/core/theme/`
> remains the only place a memox token is defined; the CSS here was *generated
> from* it and will drift the moment the Dart changes. Read it to see what the
> redesign proposes; never treat a value here as authoritative, and never edit a
> Dart token to match a CSS one. Nothing in `design_system/` is compiled,
> analyzed or tested by any repo gate.
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

Recorded because a snapshot that silently contradicts `lib/` is worse than no
snapshot. In every row the repo is right and the snapshot is stale.

| Snapshot says | Repo does | Note |
|---|---|---|
| `MxErrorState.prompt.md`: "Retry is a `secondary` button, never primary" | Retry is **primary** | Changed in M4.10n so `MxErrorState` and `MxEmptyState` — two states one keystroke apart — stop looking like different components. |
| `tokens/colors.css`: `--color-web-letterbox:#6E7288` | `AppColors.webLetterbox` is `#14162A` | Not a straight contradiction — `#6E7288` is the grey `ui_kits/.../index.html` paints *behind its phone frame*, and the token was named after it. The repo's value is the seed-tinted near-black the Flutter web build letterboxes with. Two different surfaces sharing one token name. |
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

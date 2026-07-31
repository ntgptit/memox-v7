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
- [ ] `_adherence.oxlintrc.json`

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
- [ ] `core/` — 8 `.jsx` + `core.card.html`
- [ ] `feedback/` — 6 `.jsx` + `feedback.card.html`
- [ ] `navigation/` — 4 `.jsx` + `navigation.card.html`

## guidelines/

- [ ] 20 `*.card.html` specimen cards

## ui_kits/memox-app/

- [ ] `index.html` · `kitdata.js`
- [x] `README.md`
- [x] `DeckLevelScreen.jsx`
- [ ] `DeckForms.jsx` · `ReviewScreen.jsx` · `ProfileScreen.jsx`

## Not imported, and why

| Path | Reason |
|---|---|
| `assets/fonts/*.ttf`, `*.txt` | Already in this repo at `assets/fonts/` — the design project copied them **from** here. A second copy is ~1 MB of binary and a second thing to keep in step. `tokens/fonts.css` was re-pointed at `../../assets/fonts/` instead; that edit is the **only** deviation from the source project and is commented in the file itself. |
| `test/design_preview/goldens/*.png` | Same: these are this repo's own goldens, copied out. `test/design_preview/goldens/` is canonical. |
| `web/favicon.png`, `web/icons/Icon-192.png` | Flutter's untouched defaults, already in `web/`. |
| `_ds_bundle.js` | A generated concatenation of the component sources that are imported individually here. Nothing in it is not already in `components/`. |
| `uploads/학비_송금_한이찬.jpg` | **Not a design file.** The name reads as a personal tuition-remittance document. It has no relationship to the design system and does not belong in a source repository — flagged rather than copied. |

## Where the snapshot already disagrees with the code

Recorded because a snapshot that silently contradicts `lib/` is worse than no
snapshot. In every row the repo is right and the snapshot is stale.

| Snapshot says | Repo does | Note |
|---|---|---|
| `MxErrorState.prompt.md`: "Retry is a `secondary` button, never primary" | Retry is **primary** | Changed in M4.10n so `MxErrorState` and `MxEmptyState` — two states one keystroke apart — stop looking like different components. |
| `tokens/colors.css`: `--color-web-letterbox:#6E7288` | `AppColors.webLetterbox` is `#14162A` | The snapshot's value is a mid grey; the repo's is the seed-tinted near-black the web build actually letterboxes with. |
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

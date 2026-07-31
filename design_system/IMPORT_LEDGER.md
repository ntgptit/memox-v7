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
- [ ] `core/` — 8 components × (`.jsx`, `.d.ts`, `.prompt.md`) + `core.card.html`
- [ ] `feedback/` — 7 components × 3 + `feedback.card.html`
- [ ] `navigation/` — 4 components × 3 + `navigation.card.html`

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

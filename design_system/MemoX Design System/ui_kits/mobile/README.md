# MemoX — Mobile UI Kit

An interactive click-through gallery of MemoX mobile screens, built in HTML/JSX as a
visual reference for the Flutter implementation in `lib/features/**`.

`index.html` renders every screen as a static phone frame on one scrollable stage, with a
**Light / Dark** toggle in the header (dark mode is the scoped *Tokyo Nebula* theme). Screens
are visual-only — `go()` is a no-op, so frames don't navigate; each frame just shows one state.

> **Product-truth redesign (2026-09):** a second gallery lives in
> [`v2/`](./v2/index.html) — the product screens rebuilt from
> `docs/claude-design/` (deck tree instead of folders, four top-level areas, every
> applicable state, EN/VI copy switch). This v1 kit is unchanged; see
> [`v2/README.md`](./v2/README.md) for what it covers and which screens here the
> product no longer has.

> **Audit pass:** see [`AUDIT.md`](./AUDIT.md) for the Flutter-handoff review — what was
> fixed (apostrophe-escape content bug, icon/nav/focus accessibility, 44px hit targets,
> reduced-motion, a new reusable `OfflineBanner` + Dashboard `offline` state) and what is
> flagged for a product decision (gradients in chrome, self-hosted fonts/icons).

## Screens

The gallery is ordered by **user journey** — first-run → home → browse → manage a deck →
study → result → insights → settings — and numbered `01`–`23` in that flow. Most screens ship
several labelled **state variants** so every empty / loading / error / overlay case is visible
side by side.

| # | Screen | States shown |
|---|--------|--------------|
| **1 · First run** | | |
| 01 | **Onboarding** | welcome · zero state · create deck · deck for import · signing in · restore prompt · restoring · restore failed · import handoff |
| **2 · Home** | | |
| 02 | **Dashboard** | loaded · loading · onboarding · goal off · resume only · streak broken · error · offline · multi resume |
| **3 · Library** | | |
| 03 | **Library overview** | loaded · loading · empty · error · search · overflow sheet |
| 04 | **Folder detail** | decks · subfolders · unlocked · search empty · loading · error · delete · move sheet |
| 05 | **Library search** | empty · loading · results · no results · error |
| **4 · Deck & cards** | | |
| 06 | **Flashcard list** | loaded · empty · search empty · loading · error · delete card · delete deck · reorder |
| 07 | **Flashcard create** | empty · valid · details open · validation · saving · save failed |
| 08 | **Flashcard edit** | loaded · loading · load error · validation · saving · save failed · delete |
| 09 | **Flashcard history** | loaded · empty · loading · error · partial |
| 10 | **Deck import** | empty · file selected · parsing · preview all · preview mixed · importing · success · partial · failed |
| 11 | **Tag management** | loaded · loading · empty · search empty · action sheet · rename · rename→merge · merge sheet · delete · busy · op error |
| **5 · Study** | | |
| 12 | **Study · Review** | term + meaning, swipe-to-next |
| 13 | **Study · Match** | pair fronts & backs |
| 14 | **Study · Guess** | multiple choice A–E |
| 15 | **Study · Recall** | hidden · revealed |
| 16 | **Study · Fill** | input · wrong |
| 17 | **Study result** | loaded · loading · goal off · save failed · defensive · tough empty |
| **6 · Insights** | | |
| 18 | **Stats** | weekly chart + per-deck mastery |
| 19 | **Progress** | week · month · loading · empty · insufficient · partial · error |
| **7 · Settings** | | |
| 20 | **Settings** | populated · loading · signed out · signing in · sync error |
| 21 | **Account sync** | signed out · signing in · failed · no backup · ready · uploading · restore warn · restoring · token expired |
| 22 | **Learning settings** | goal on/off · reminder on · perm denied · saving |
| 23 | **Audio & speech** | Korean · English · loading · no voices · engine error · playing · saving |

## Conventions

- `StatusBar`, `BottomNav`, `Breadcrumb`, `StudyTopBar` and `Ic` are shared layout/icon
  primitives; everything else is a screen-level component that takes a `state` prop.
- **Shared primitives (2026-09 extraction).** `_shared.jsx` also owns `Scrim`, `Dialog`,
  `BottomSheet`, `Skeleton`, `Spinner`, `IconTile`, `ListRow`, `EmptyState`, `ErrorState`,
  `Toggle`, `TextField` and `StatusBadge`. Each replaced 2–7 divergent per-screen copies.
  Do not re-declare them in a screen file — read them off `window` (or take them from `ctx`
  in a state module). Screen-specific rows and cards stay local; only the repeated
  visual contract is shared.
- **Component CSS lives in `../../components.css`** (linked via `../../styles.css`), not
  inline here. `index.html` keeps only frame CSS: the phone bezel, the `.app` column and
  scroll clearance. Editing `.card`, `.pill-btn`, `.icon-btn`, `.fab`, `.appbar`,
  `.bottom-nav`, `.icon-tile` or `.ov` means editing `components.css` — which is also what
  `components/Mx*.jsx` renders, so the two layers cannot drift again.
- `masteryColor(pct)` maps a 0–1 mastery value to a card-status token (learning → reviewing → mastered).
- `Phone` wraps each frame; `App` builds the `screens` array and the theme toggle.
- Icons via the Lucide CDN (substitute for Flutter's Material Symbols).
- All colour / spacing / radius / type values come from `../../colors_and_type.css`. Dark mode is
  applied through the scoped `.memox-dark` block in `index.html` (the in-page Light/Dark toggle),
  which mirrors the Tokyo Nebula dark tokens from the shared stylesheet.

## File layout

Each screen lives in its own file under [`screens/`](./screens) so it can be reviewed and
edited in isolation instead of scrolling one ~11k-line `index.html`:

- `screens/_shared.jsx` — shared chrome (`StatusBar`, `Ic`, `BottomNav`, `Breadcrumb`,
  `OfflineBanner`, `StudyTopBar`, `masteryColor`) **plus the shared primitives**
  (`Scrim`, `Dialog`, `BottomSheet`, `Skeleton`, `Spinner`, `IconTile`, `ListRow`,
  `EmptyState`, `ErrorState`, `Toggle`, `TextField`, `StatusBadge`, `SearchField`,
  `Badge`, `Fab`, `MobileScaffold`). Loaded **first**; publishes these to `window`.
- `screens/<ScreenName>.jsx` — one component per file (e.g. `DashboardScreen.jsx`). Each reads
  the shared chrome from `window`, defines its screen, and publishes itself back to `window`.
- `index.html` — loads `_shared.jsx` then every screen as ordered `<script type="text/babel" src>`
  tags, and keeps the gallery harness (`GROUPS`, `ScreenRow`, token/widget docs, `App`) inline.

Each file is wrapped in an IIFE so its top-level bindings stay local (sibling `<script>` tags
otherwise share one global scope); components cross files only via `window`. To add a screen:
create `screens/NewScreen.jsx` (copy an existing file's wrapper), add a `<script src>` line in
`index.html`, and a `GROUPS` entry.

## Source mapping

Each screen mirrors a feature page under `lib/features/**` (e.g. study modes →
`lib/features/study/**`, library/folders/flashcards → `lib/features/library/**` and
`lib/features/decks/**`, settings/sync/audio → `lib/features/settings/**`). Use the Flutter
feature folders as the source of truth for behaviour; this kit only fixes the visual language.

# MemoX Mobile UI Kit — Systemic Audit

Scope: `ui_kits/mobile/index.html` + `screens/**` + `colors_and_type.css`.
> **Status — historical.** This is the 2026-08 audit snapshot, kept for the reasoning.
> Items marked **[RESOLVED]** were fixed in the 2026-09 normalization pass and no longer
> describe current state; read the unmarked items as still open. Current contract lives in
> `colors_and_type.css` and the token tables of `components.html`.

Method: source inspection (all shared chrome, Dashboard/Library/FlashcardList shells, FAB/dialog/sheet/badge patterns, token file) + visual check of Dashboard light & dark. No code changed.

---

## 1. Systemic issues (grouped by severity)

### CRITICAL
- **C1 — Dark-mode primary token contradiction.** The `@media (prefers-color-scheme: dark)` block in `colors_and_type.css` lifts `--memox-primary` to `#8B9AFF` *"lifted for AA on #0A0E27"*, but the toggle-driven `.memox-dark` scope in `index.html` **resets it back to `#5265F5`**. The preview (and therefore the Flutter reference) renders solid primary CTAs / links on `#0A0E27` with the un-lifted color — failing the exact AA the system claims to protect. Affects every "Resume", "Start today's review", primary link in dark.
- **[MOSTLY RESOLVED 2026-09] C2 — Tokens are bypassed by inline literals.** Screens now read color roles; the only raw hex left is the Google brand mark and the gallery chrome, both documented. Original finding: Pervasive hardcoded `rgba()` and hex-alpha: error `rgba(220,72,72,…)`, streak `rgba(217,137,30,…)`, mastery `rgba(43,168,139,…)`, deck dots `${col}1F`. These do **not** track theme and have no Dart symbol — defeating the stated migration goal (the token file exists to be the 1:1 source of truth).
- **C3 — Core components are duplicated, not shared.** FAB (2 hand-rolled copies, divergent), Scrim, Dialog shell, bottom-sheet shell, due/count badge, filter chips, and per-screen `EmptyCard`/`ErrorCard` are re-implemented in each screen file with slightly different specs. There is **no single source of truth** for these — Flutter would receive conflicting blueprints for the same widget.

### HIGH
- **[RESOLVED 2026-09] H1 — Radius scale chaos.** Radii now sit on the 4dp grid; `--memox-radius-card` is 20 (matches `.card`) and `--memox-radius-fab` is 16 (matches `.fab`). Original finding: Token scale is 4/8/12/16/24/28, but code freely uses 9, 11, 13, 14, 18, 20. `.card` is `20px` ≠ `--memox-radius-card:16`; FAB is `16px` ≠ `--memox-radius-fab:28`.
- **[RESOLVED 2026-09] H2 — Screen gutter inconsistent.** `--memox-space-screen` is now 16px and equals `--screen-gutter`; every padding/margin/gap is on the 4dp grid. Original finding: `--memox-space-screen:24` is **never used**. Actual horizontal padding is a mix of 14 / 18 / 20 across `.scroll`, app bars, and headers. Bottom scroll padding to clear nav/FAB is hand-tuned per screen (14 / 100 / 110) rather than derived.
- **[RESOLVED 2026-09] H3 — FAB clearance + glow are magic numbers.** Clearance is derived (`--clear-fab` / `--clear-fab-nav`) and the colored glow was replaced by the neutral `--memox-shadow-fab`. `--memox-size-fab` is now 52px, matching `--fab-h`. Original finding: Library FAB `bottom:84` (to clear the ~80px nav), FlashcardList FAB `bottom:24`. Not token-derived. Both use a loud colored glow `0 8px 22px primary 36%`, far above the system's `--memox-shadow-max-opacity:0.06` elevation cap. `--memox-size-fab:56` / `--memox-radius-fab:28` unused.
- **H4 — Sub-comfort touch targets.** Filter/sort chips are 28px tall; "other paused sessions" button 32px; bottom-nav labels 10px. The global `.icon-btn::after` 48px expander covers icon buttons, but these non-`.icon-btn` controls have no hit-area floor (< 44/48px).
- **H5 — Search bar is a desktop fake.** It's a static `<span>` with a blinking fake caret and a **`K` (Cmd-K) keyboard hint** — a desktop affordance on a phone frame. Not a real input, no clear/voice button, height 44 < `--memox-size-input:52`. Misleading for Flutter implementation.
- **H6 — Competing CTAs.** Dashboard stacks up to three full-width strong actions: "Resume" (solid), "Start today's review" (solid), "Start new learning" (primary-8% tint). The tinted button reads nearly as loud as a true CTA → diluted "one thing to do now."
- **H7 — Elevation system bypassed; dark separation too weak.** Dialogs use `0 16px 40px rgba(0,0,0,0.32)`; FAB glow as above — the `--memox-shadow-level1..5` tokens are largely unused. In dark, `.card` drops shadow and relies on `border-ghost rgba(139,154,255,0.16)`, but many inline cards omit that border, so card/background separation rests on near-adjacent surface steps (`#131A3A` vs `#1B2249`).

### MEDIUM
- **M1 — Badge / chip inconsistency.** "due" badge (primary-10% tint) is copy-pasted in Dashboard, Library, FlashcardList; search count badge uses a different `surface-container` fill; streak/expired badges use streak-tint. Two separate chip implementations (`.pill-btn` vs bare `<button>`). Spacing bug: `{n} due` renders cramped as "23due" in the narrow badge (confirmed on Dashboard).
- **M2 — Dark contrast of faint elements.** `outline-variant #2A3267` used for borders/dividers is nearly invisible on paper-indigo cards; 12px `on-surface-variant #A4ACD0` secondary text is borderline AA on dark surfaces.
- **[RESOLVED 2026-09] M3 — Overlines weakened too far.** `.ov` is 12px / 700. Original finding: `.ov` was reduced to 10.5px / 600 / opacity .85 — too faint in dark mode for section scanning.
- **[PARTLY RESOLVED 2026-09] M4 — Small-type density.** 12px is now a hard floor — no 9 / 10.5 / 11px type remains. The reliance on 12px secondary text stands. Original finding: Heavy reliance on 12px secondary/meta text on a 390px frame, plus 10.5px overlines and 9px skeleton labels — below comfortable reading size.
- **[RESOLVED 2026-09] M5 — Card padding has no rhythm.** `.card` is 20px and equals `--memox-space-card`; all padding is on the 4dp grid. Original finding: Values range 12 / 14 / 16 / 18 / 22 / 32 with no consistent step.

### LOW
- **L1 — Skeletons re-implemented inline.** `Skel` lives inside Dashboard; Library/Folder loading states hand-roll equivalent pulse spans instead of sharing it.
- **L2 — Ad-hoc token naming.** `--memox-error-fill` introduced inline in `body` + dark scope rather than in the token file's semantic set.
- **L3 — Nav height doc mismatch.** `--memox-size-bottom-nav:80` vs rendered nav (64px + wrap padding). Works out to ~80 but isn't sourced from the token.
- **L4 — Decorative loops.** Pulsing dots / scrim animations exist but are correctly quieted by the `prefers-reduced-motion` block — acceptable.

---

## 2. Fix globally vs. screen-by-screen

**Fix GLOBALLY (in `colors_and_type.css`, `_shared.jsx`, and the `.card`/`.pill-btn` primitives) — one change fixes every screen:**
- C1 dark primary resolution; AA contrast pass (C1, M2).
- C2 replace inline `rgba()`/hex-alpha with `color-mix()` on tokens.
- C3 + L1 promote FAB, Dialog, BottomSheet, Badge, Chip, EmptyState, ErrorState, SearchField, Skel into `_shared.jsx`.
- H1 collapse radius usage to the token scale; map `.card`→`radius-card`, FAB→`radius/size-fab`.
- H2 define one screen-gutter constant + a nav/FAB safe-inset; apply via a shared scaffold wrapper.
- H3/H7 route all elevation through `shadow-level*`; retire the colored FAB glow.
- H4 add a min hit-area floor to chips/secondary buttons (extend the `::after` pattern).
- M3 retune `.ov`.

**Fix SCREEN-BY-SCREEN (judgement calls, do after globals land):**
- H6 decide *the* primary action per screen (Dashboard, Library, FlashcardList).
- H5 real search-field behavior per search surface; drop the Cmd-K hint.
- M1 badge-spacing/copy and which fill each context uses.
- M4/M5 per-screen density and copy tuning.

> Rule of thumb: anything that is a **token, a primitive, or a repeated widget** is global. Anything that is a **composition or content decision** is per-screen. ~70% of the issues above are global.

---

## 3. Phased implementation plan

**Phase 0 — Token & contrast hardening** *(global, no visual redesign; lowest risk, highest migration payoff)*
Resolve the dark-primary conflict, run an AA pass, collapse radius/size/elevation token usage, replace inline color literals with token `color-mix()`. Moves the mock back to being a true 1:1 mirror of the Dart tokens.

**Phase 1 — Shared-component extraction**
Lift FAB, Dialog, BottomSheet, Badge, Chip, EmptyState, ErrorState, SearchField, Skel into `_shared.jsx`; refactor screens to consume them. Eliminates drift and gives Flutter one widget spec each.

**Phase 2 — Layout system**
Introduce a screen-gutter constant and a nav/FAB safe-inset; standardize `.scroll` bottom padding and FAB clearance off those constants (maps cleanly to a Flutter `Scaffold` + `SafeArea`).

**Phase 3 — Hierarchy & interaction polish**
Establish one dominant CTA per screen, apply the touch-target floor, make search behave like a real input, fix badge spacing/fills.

**Phase 4 — Dark-mode & a11y verification**
Border visibility, overline legibility, AA re-check across all dark states; confirm reduced-motion.

**Phase 5 — Flutter handoff mapping**
Verify every value resolves to a Dart token; document FAB/Dialog/Sheet/Badge/SearchField as named widgets with variant lists.

---
*Audit only — no source files were modified.*

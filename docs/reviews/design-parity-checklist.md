# Design parity checklist — `design_system/` (CSS/JSX) ↔ `lib/` (Dart)

Since M4.10p the design system is authoritative for token **values**; this file
widens that to everything else the design encodes — theme data, shared widgets,
how tokens are used, corner radii, states, layout. It exists so the review is
**file-by-file rather than impression-by-impression**: every artefact on the
design side appears exactly once below, paired with what it maps to in `lib/`.

**Status key.** `[x]` reviewed 1:1, verdict recorded · `[ ]` not yet reviewed.
A verdict is one of **match** (nothing to do), **drift** (Dart moves to the
design), **design-gap** (the design is missing something the app needs),
**blocked** (needs a decision or a BR before it can move).

**Scope note.** `design_system/` files that carry no rule are excluded and listed
at the bottom, so their absence here is deliberate rather than an oversight.

---

## A · Tokens — `design_system/tokens/*.css`

| # | Design source | Flutter target | Compare | Status | Verdict |
|---|---|---|---|---|---|
| A1 | `colors.css` (light scope) | `app_colors.dart` | every `--color-*` hex | [x] | **drift → resolved M4.10p.** 11 of 40 taken from CSS |
| A2 | `colors.css` (`[data-theme=dark]`) | `app_colors.dart` | every dark override | [x] | same, resolved |
| A3 | `colors.css` progress + streak families | `app_semantic_colors.dart` | 5 tokens with no Dart counterpart | [x] | **progress resolved M4.10r** — `MxProgressBar` is the caller. Streak still blocked: no feature, and a fifth hue |
| A4 | `typography.css` sizes + leading | `app_typography.dart` | 15 M3 styles, measured off the built `TextTheme` | [x] | **match** (see §A-detail) |
| A5 | `typography.css` tracking | same | `--tracking-*` | [x] | **match** |
| A6 | `typography.css` weights | same | which style gets which `--weight-*` | [x] | **match** — 400/500/600/700 land on the same styles |
| A7 | `typography.css` `--tracking-section-label` 1.1px | `SectionLabel` (`preview_harness.dart`) | section-label treatment | [x] | **match**, and tokenised — the 1.1 was a literal at the call site; now `AppTypography.sectionLabelTracking` |
| A8 | `fonts.css` | `pubspec.yaml`, `app_typography.dart` | families, axes, bundling | [x] | **match** — both variable, both bundled |
| A9 | `spacing.css` | `app_spacing.dart` | 6 steps + 48 floor | [x] | **match** |
| A10 | `spacing.css` `--icon-*` | `app_icon_size.dart` | 16 / 24 / 40 | [x] | **match** |
| A11 | `radius.css` | `app_radius.dart` | 8 / 12 / 16 / 999 | [x] | **match** |
| A12 | `elevation.css` levels | `app_elevation.dart` | 0 / 1 / 3 / 8 | [x] | **match** |
| A13 | `elevation.css` shadows | `shadowsFor()` | the three shadow recipes, and dark = none | [x] | **match** — `shadowsFor` *derives* all three: alpha `0.06+0.01*level`, blur `3*level`, offset `(0,level)` reproduce the CSS exactly at 1/3/8 |
| A14 | `elevation.css` borders | `app_theme.dart`, `mx_text_field.dart` | hairline 1 / input 1.5 / focus 2 | [x] | **match** — hairline 1, input 1.5, focus ring 2 |
| A15 | `motion.css` | `app_durations.dart` | 120 / 200 / 320 | [x] | **match** |
| A16 | `motion.css` easing | — | `--ease-standard`, `--ease-decelerate` | [x] | **drift → fixed** — Dart had no curve token and `Curves.decelerate` is `(0,0,0.2,1)`, not the design's `(0,0,0,1)` |
| A17 | `layout.css` breakpoints | `app_breakpoints.dart` | 360 / 600 | [x] | **match** |
| A18 | `layout.css` `--nav-width-per-destination` | `mx_navigation_bar.dart` | 120 | [x] | **match** — 120 |
| A19 | `layout.css` `--frame-*` | `web/` letterbox | preview frame only | [x] | n/a — the preview frame has no Flutter counterpart and needs none |

### A-detail · typography, measured

Read off the built `TextTheme` through a `BuildContext`, not from source — the
source only overrides family, weight and two specifics, and the rest comes from
Material's own scale at render time.

| Style | CSS size / leading / tracking | Flutter (measured) |
|---|---|---|
| display-lg | 57 / 64px / — | 57 / 1.12 / −0.25 |
| display-md | 45 / 52px | 45 / 1.16 / 0 |
| display-sm | 36 / 44px | 36 / 1.22 / 0 |
| headline-lg | 32 / 40px | 32 / 1.25 / 0 |
| **card prompt** | **30 / 1.22 / −0.5** | **30 / 1.22 / −0.5** |
| headline-sm | 24 / 32px | 24 / 1.33 / 0 |
| title-lg | 22 / 28px | 22 / 1.27 / 0 |
| title-md | 16 / 24px / 0.15 | 16 / 1.5 / 0.15 |
| title-sm | 14 / 20px / 0.1 | 14 / 1.43 / 0.1 |
| body-lg | 16 / 24px / 0.5 | 16 / 1.5 / 0.5 |
| **body-md** | **14 / 1.45 / 0.25** | **14 / 1.45 / 0.25** |
| body-sm | 12 / 16px / 0.4 | 12 / 1.33 / 0.4 |
| label-lg | 14 / 20px / 0.1 | 14 / 1.43 / 0.1 |
| label-md | 12 / 16px / 0.5 | 12 / 1.33 / 0.5 |
| label-sm | 11 / 16px / 0.5 | 11 / 1.45 / 0.5 |

Leading is expressed in px on the CSS side and as a multiplier in Dart; every
pair agrees to within a rounding step. Both deliberate overrides — the card
prompt and body-md's 1.45 — are identical on both sides.

---

## B · Theme data — how tokens become a rendered widget

| # | Design source | Flutter target | Compare | Status | Verdict |
|---|---|---|---|---|---|
| B1 | `mx.css` `.mx-btn--primary/--secondary/--destructive` | `app_button_themes.dart` | fill, label colour, border, radius, min height | [x] | **match** - 12/24 padding, radius 12, 64x48 floor, 12% press lerp, all identical |
| B2 | `mx.css` `:hover` / `:active` on buttons | `app_button_themes.dart` overlays | 4% / 6% / 10% / 12% state layers | [x] | **drift (F1)** - press 12% matches; **hover is unspecified in Dart** and falls back to Material |
| B3 | `mx.css` `:disabled` | `disabledSurfaceTint()` | precomputed solid vs alpha | [x] | **match** - fill + 38% label + transparent secondary all agree |
| B4 | `mx.css` `.mx-pill` | `app_chip_theme.dart` | fill, selected pair, border, 48 target | [x] | **match** - every property, including 8/12 padding and no checkmark |
| B5 | `mx.css` `.mx-field*` | `app_theme.dart` `inputDecorationTheme` | 1.5px stroke, radius, focus = hue not width, error | [x] | **match** - unfilled, 12/16 padding, hue-only focus |
| B6 | `mx.css` `.mx-nav` | `app_theme.dart` `navigationBarTheme` | page-colour fill, hairline, indicator pair | [x] | **drift (F2, F3)** - page fill and elevation 0 match; **no top hairline**, and the indicator role is disputed |
| B7 | `mx.css` `.mx-scrim` (60%) | `modalBarrierColor()` | barrier opacity per mode | [x] | **drift (F16)** - design 60% flat, Dart 48% light / 72% dark |
| B8 | `mx.css` `.mx-dialog` / `.mx-sheet` | `app_theme.dart` dialog + sheet themes | radius, surface, shadow | [x] | **drift (F15)** - sheet matches entirely; the dialog is missing `--shadow-overlay` |
| B9 | `mx.css` `.mx-spinner` | `buildProgressIndicatorTheme()` | colour source | [x] | **drift (F14)** - and the Dart widget overrides its own theme |
| B10 | `readme.md` "States" | `app_theme.dart` overlays | hover 8/6/4, press 12, focus 2px ring | [x] | **match** since M4.10q — hover 6%, press 12%, focus ring 2px |
| B11 | `readme.md` "Layout rules" | `app_theme.dart` appBar + `MxContentShell` | no elevation, no scroll tint, page-colour bar | [x] | **drift (F4, F11)** - page colour and zero elevation match; no scroll hairline, and the FAB shape differs |
| B12 | — | `app_overlay_themes.dart` tooltip, selection, divider, scrollbar | design has no counterpart | [x] | **design-gap, as expected** — tooltip, text selection, divider and scrollbar have no CSS counterpart; the design leaves them to the browser as Flutter left them to Material until M4.10j |
| B13 | `index.html` `COMPACT_BELOW` behaviour | `app_compact_scale.dart` | title 22→20, prompt 30→26, button padding | [x] | **match** — title 22→20, card prompt 30→26, button padding 24→12, same 360 breakpoint |

---

## C · Shared widgets — 18 design components ↔ 15 Dart

Each row compares the `.jsx` **and** its `.prompt.md` and `.d.ts` against the
Dart widget: props, defaults, states, radius, spacing, semantics.

| # | Design component | Flutter | Status | Verdict |
|---|---|---|---|---|
| C1 | `MxActionButton` | `mx_action_button.dart` | [x] | **match** - `isBlock`/`isCompact`/`isDisabled` are expressed idiomatically (caller width, global compact scale, null callback) |
| C2 | `MxIconButton` | `mx_icon_button.dart` | [x] | **match** - radius 12, 48 square, `onSurfaceVariant`; `filled` is expressed by which `IconData` the caller passes |
| C3 | `MxPillButton` | `mx_pill_button.dart` | [x] | **match** - props one-for-one, 48 target via `MaterialTapTargetSize.padded` |
| C4 | `MxCard` | `mx_card.dart` | [x] | **match** - radius 16, hairline, `--shadow-card` default, `--space-lg` padding |
| C5 | `MxTextField` | `mx_text_field.dart` | [x] | **match** — unfilled, 1.5 stroke, hue-only focus, error shows a message and not colour alone. `onSurface` is web-only: Flutter's outline gaps for the label, so there is no backing to match |
| C6 | `MxListTile` | `mx_list_tile.dart` | [x] | **match** - radius 12, selected fill `surfaceMuted` + primary title, 2-line clamp both sides |
| C7 | `MxIcon` | — (Flutter uses `Icons.*`) | [x] | n/a — Flutter reaches `Icons.*` directly; the wrapper exists because the web has no bundled set |
| C8 | `MxProgressBar` | `mx_progress_bar.dart` | [x] | **built M4.10r** — BR-88 unblocked it |
| C9 | `MxEmptyState` | `mx_empty_state.dart` | [x] | **match** - 40px primary glyph, 24 padding, 16/8 rhythm, `check_circle_outline` default |
| C10 | `MxErrorState` | `mx_error_state.dart` | [x] | **deliberate divergence, repo wins** — retry is primary. The design's note is prose, and M4.10n changed it so `MxErrorState` and `MxEmptyState` stop looking like two components |
| C11 | `MxLoadingState` | `mx_loading_state.dart` | [x] | **drift (F14)** - passes `primary` explicitly, defeating the theme that exists to avoid it |
| C12 | `MxAsyncView` | `mx_async_view.dart` | [x] | **match** — `error` is required, so no screen can inherit a generic failure sentence |
| C13 | `MxConfirmDialog` | `mx_confirm_dialog.dart` | [x] | **match** — `shouldAutofocus: _isDestructive` puts initial focus on Cancel |
| C14 | `MxActionSheet` | `mx_action_sheet.dart` | [x] | **match** — `!isEnabled` is tested first, so disabled beats destructive |
| C15 | `MxNavigationBar` | `mx_navigation_bar.dart` | [x] | **match** — `selectedIcon` carries the filled twin, labels always shown |
| C16 | `MxBreadcrumb` | `mx_breadcrumb.dart` | [x] | **drift (F5-F8)** - no fold, no `rootIcon`, label one size up, link colour full-strength |
| C17 | `MxSearchField` | — | [x] | **reviewed, not built** — the design's contract is clear and nothing blocks it; it is the one substantial piece still outstanding |
| C18 | `MxContentShell` | `mx_content_shell.dart` | [x] | **drift (F9, F10)** - no `subheader`, no `leading`; gutters match exactly |

---

## D · Screens and feature widgets

| # | Design source | Flutter target | Status | Verdict |
|---|---|---|---|---|
| D1 | `DeckLevelScreen.jsx` shell + subheader | `deck_list_screen.dart` | [x] | **done M4.10q** — `subheader` holds the path |
| D2 | `DeckLevelScreen.jsx` `DeckCard` | `deck_tile_widget.dart` | [x] | **rebuilt M4.10s** — flat card, open region, due chip, three foot states. Study pill deliberately absent: no session to start until M5 |
| D3 | `DeckLevelScreen.jsx` filter/sort row | `deck_list_toolbar_widget.dart` | [x] | **gap → fixed** — the design heads the list "Your decks"/"Sub-decks" beside the pills; there was nothing saying what the pills filtered |
| D4 | `DeckLevelScreen.jsx` breadcrumb use | `deck_path_widget.dart` | [x] | **done M4.10q** — fold, root icon, quiet weight |
| D5 | `DeckLevelScreen.jsx` `LevelEmpty` (three empties) | `deck_list_screen.dart` empty states | [x] | **match** — five empty states, more than the design's three: `card`-typed decks and a failed read are cases the kit has no fixture for |
| D6 | `DeckLevelScreen.jsx` `LevelSummary` | `deck_level_summary_widget.dart` | [x] | **built M4.10t**, minus the streak chip and Start studying — both need M5 |
| D7 | `DeckLevelScreen.jsx` `SearchResults` | — | [x] | **reviewed, not built** — needs a recursive name query, a contract method and a use case. Not blocked on a rule, only on the work |
| D8 | `DeckForms.jsx` | `deck_form_widget.dart` | [x] | **match** — one form for create-root, create-sub and rename |
| D9 | `DeckForms.jsx` `SchedulerChoice` | `deck_form_widget.dart` radio rows | [x] | **match** — radio rows, `SchedulerType?` null until chosen, so nothing is preselected (BR-11) |
| D10 | `index.html` action sheet wiring | `deck_actions_widget.dart` | [x] | **match** — same four actions, reset disabled rather than hidden |
| D11 | `index.html` destructive confirm | `deck_confirm_widget.dart` | [x] | **match** — destructive confirm names the counts |
| D12 | `index.html` `MxNavigationBar` mount | `app_navigation_shell.dart` | [x] | **match** — two destinations; the kit's third is its "You" tab, which is M5 territory |
| D13 | `ReviewScreen.jsx` | `review_screen_preview_test.dart` harness | [x] | **partly done M4.10p** — `VerdictAction` ground fixed. The rest is a preview harness, not a screen: the review slice is M5 |
| D14 | `ProfileScreen.jsx` | `settings_preview_test.dart` harness | [x] | **preview harness only** — settings is not a built screen, so there is nothing to bring to the design yet |
| D15 | — | `deck_labels_widget.dart`, `deck_level_error_widget.dart`, `move_deck_sheet_widget.dart` | [x] | no design counterpart, and none needed — deck labels, level error and the move sheet are this app's own |

---

## E · Cross-cutting rules from `readme.md`

| # | Rule | Where it must hold | Status | Verdict |
|---|---|---|---|---|
| E1 | Radius policy: 8 chips · 12 buttons+inputs · 16 cards+sheets · 999 pills | every widget | [x] | **match** — zero raw `BorderRadius.circular(<number>)` anywhere in `lib/` |
| E2 | 48px is a floor no prop can shrink | every interactive widget | [x] | **match** — 14 references to `minimumTouchTarget`, no component exposes a prop that could shrink it |
| E3 | One accent, secondary actions neutral | buttons, verdicts | [x] | **match** — `secondaryAction` is neutral in both modes and `app_palette_test.dart` asserts it carries less hue than the accent |
| E4 | Colour never alone — glyph + word + colour | every state | [x] | **match** — the due chip is glyph + words + colour; the deck glyph state is announced |
| E5 | Icons outlined at rest, filled when active | nav bar, tiles | [x] | **match** — 12 `Icons.*_outlined` at rest, `selectedIcon` filled |
| E6 | Three icon sizes only | every icon call site | [x] | **match** — zero raw `size: <number>` on any `Icon` in `lib/` |
| E7 | No gradient, photo, illustration, texture | whole app | [x] | **match** — zero gradients, images or decoration images in `lib/` |
| E8 | Spinner, never skeleton | loading states | [x] | **match** — the only occurrence of the word "skeleton" is the comment explaining why there is none |
| E9 | Sentence case; UPPERCASE only for section labels | ARB files | [x] | **match** — sentence case throughout; the section label is uppercased by the widget, not stored uppercase |
| E10 | Middle dot separates facts on one line | ARB files | [x] | **match** — the middle dot separates facts on the deck meta line |
| E11 | No emoji anywhere | ARB files, code | [x] | **match** — no character above U+2100 in either ARB |
| E12 | Error copy belongs to the screen, not the component | `MxErrorState` callers | [x] | **match** — `MxErrorState` maps no failure type; every caller passes its own sentence |

---

## Excluded, deliberately

| Path | Why it carries no rule |
|---|---|
| `design_system/_adherence.oxlintrc.json` | Lint config for JSX; its content is the `.d.ts` prop lists, already covered by §C |
| `design_system/_ds_manifest.json`, `thumbnail.html` | Gallery plumbing |
| `design_system/github.md`, `IMPORT_LEDGER.md` | Provenance, not design |
| `design_system/SKILL.md` | Agent entry point |
| `design_system/styles.css` | `@import` list only |
| `guidelines/*.card.html` (not yet imported) | Rendered specimens of values already in `tokens/` |

---

## Findings so far

Numbered so the checklist rows can point at them. Ordered by how much each
changes what a user sees.

### F5 - `MxBreadcrumb` never folds, and decks go ten levels deep

The design folds the middle of the path into an expandable ellipsis past four
steps (`collapseAfter`, default 4), keeping the two ends the user actually
navigates to. `mx_breadcrumb.dart` has no fold at all: it scrolls horizontally
and that is the whole strategy. BR-55 allows ten levels, so a deep path becomes
a strip the user has to scrub sideways to read.

**The largest single gap in the shared layer** - and self-contained: no domain
data, no BR.

### F6 - No `rootIcon`

The design puts a `home` glyph before the first step so the library root is
recognisable without reading it. Dart has no such prop.

### F7 - Breadcrumb type is one size too large

Design: `--text-label-md` (12px, tracking 0.5). Dart: `labelLarge` (14px,
tracking 0.1). A path strip is chrome; at 14px it competes with the app-bar
title directly above it.

### F8 - Breadcrumb links are full-strength text

Design keeps every step at `--color-text-secondary` and separates link from
current by **weight only** (semibold vs regular). Dart raises links to
`onSurface` and leaves the current step at `onSurfaceVariant`, so the path reads
louder than the design intends.

### F9 - `MxContentShell` has no `subheader`

The design pins a subheader between the app bar and the scrolling body, and that
is where the redesign puts the breadcrumb **and** the search field.

**Corrected while fixing it:** the first draft of this entry said the deck
screen's breadcrumb scrolled away. It did not - a `Column` above an `Expanded`
is already pinned. What the missing slot actually cost was ownership: the screen
re-derived the gutter with a hardcoded `AppSpacing.lg`, so the path lined up with
the rows at the wide width and not at the compact one, and there was no chrome
boundary for a scroll hairline to attach to.

### F10 - No `leading` slot

Dart relies on `AppBar`'s automatic back button. The design passes `leading`
explicitly, which is what lets the root level render no back affordance at all.

### F1 - Hover is unspecified in Dart

The design gives every control an explicit hover: 4% on cards, 6% on outlined
controls and pills, 8% neutral on rows. `buildSharedButtonStyle` resolves only
`pressed` and `focused` and returns `null` for hover, so Material's default
fills in. **Web and desktop only**, and Android is the release target (AD-04) -
but the web build is the E2E channel, so it shows up in exactly the place the
project looks at screenshots.

### F2 - The bottom bar has no top hairline

`.mx-nav` draws `border-top: 1px solid var(--color-border-subtle)`. The Flutter
`navigationBarTheme` sets background, indicator, elevation and label behaviour -
no border. Both agree the bar paints the page colour, which is precisely why the
design needs the hairline: without it, chrome and content share an edge with
nothing on it.

### F3 - The navigation indicator: the design contradicts itself

`readme.md` says the selected indicator is `secondary-container`, "used
identically for a tab, a filter pill and a chosen verdict". `mx.css` paints
`.mx-nav__pill` with **`--color-primary-container`** and uses
`secondary-container` only on the pill button. Flutter uses `secondaryContainer`
for both, which follows the prose.

**Third instance of the same pattern** - after the `danger`-saturation
contradiction at M4.10p and the breadcrumb height below, the design's prose and
its CSS disagree often enough that "follow the JSX" needs a tie-break. Proposed,
and applied throughout this review: **values win for token values; prose wins
for which token a component reaches for.** That is what M4.10p already did in
practice.

### F4 - No scroll hairline under the app bar

The design fades a hairline in under the bar once the body has actually
scrolled, so a screen whose content fits shows no line. Flutter sets
`scrolledUnderElevation: 0` and draws nothing in either state. The repo's stated
reason - a colour shift behind a flashcard reads as the card itself changing -
argues against Material's *tint*, not against a 1px line.

### F11 - The FAB is a circle; the design's is a rounded square

`floatingActionButtonTheme` sets `shape: CircleBorder()`. `.mx-shell__fab` is
56x56 with `border-radius: var(--radius-lg)` - the M3 shape - and carries
`--shadow-card`, where Flutter sets every elevation to 0.

### F12 - Breadcrumb step height: the design contradicts itself again

`MxBreadcrumb.prompt.md` says "Every step is a 48px target"; `.mx-crumbs__step`
sets `min-height: 36px`. Dart uses 48. **No change proposed** - the prose is
right, and 36 would break the 48px floor the design's own spacing token
declares.

### F14 - `MxLoadingState` overrides the theme that was written to fix it

This is the one finding that is a defect rather than a difference, and it is
this repo's, not the design's.

M4.10j set `buildProgressIndicatorTheme` to `semantic.focusRing` after measuring
that dark `primary` scores **2.81:1** against the surface it spins on - under
the 3.0 floor a graphic needs. `mx_loading_state.dart` then passes
`color: context.colors.primary` explicitly, which overrides that theme. So the
app's main loading state is the one progress indicator the fix does **not**
reach; it only ever applied to the spinners nobody had complained about.

The design says `--color-primary` too, so following the design here would keep a
measured contrast failure. **Prose loses to measurement**: the fix is to delete
the `color:` argument and let the theme supply it, which is also what the repo's
own "fix it at the rule, not the call site" rule says.

### F15 - The dialog has no shadow

`.mx-dialog` carries `box-shadow: var(--shadow-overlay)`; `dialogTheme` sets
`elevation: 0`. In dark this is a no-op - AD-14 already establishes that dark
paints no shadow - but in light a dialog currently floats on a 48% scrim with
only a hairline to separate it.

### F16 - Scrim opacity: 60% flat vs 48/72

The design uses `color-mix(var(--color-scrim) 60%)` in both modes and its readme
calls it "the 60% scrim". `modalBarrierColor()` uses **48% light / 72% dark**,
chosen at M4.10j on the reasoning that a mid scrim over a `#0A082D` page barely
registers.

Both numbers are defensible and the disagreement is about *mode-awareness*, not
about the colour. Flagged rather than changed, because taking 60% flat would
undo a measured decision to fix an unmeasured one.

### F13 - Not a finding: icon-button and list-tile corners

Recorded because it is the thing most likely to be re-checked. Flutter's
`IconButton` and `ListTile` are circular and rectangular by default, so both
looked like drift. Neither is: `iconButtonTheme` and `listTileTheme` both set
`RoundedRectangleBorder(AppRadius.md)`, which is the design's `--radius-md`.

---

## Where this stands (superseded — see below)

**25 of 77 rows reviewed.** Every token row is closed except four small ones;
the theme-data section is closed except three; nine of eighteen shared widgets
are done. Sections D (screens) and E (cross-cutting rules) are untouched.

Findings so far: **one defect (F14)**, **nine drifts** where the Dart should
move to the design (F1-F5 group, F9-F11, F15), **two design self-contradictions**
(F3, F12) and **one flagged disagreement** (F16).

Nothing here has been changed yet. This file is the plan; the fixes are the next
step, and F5 (breadcrumb folding) and F9 (`subheader`) are the two that change
what a user actually sees.

---

## Round 2 - what was fixed

`flutter analyze` clean, **959 tests pass**, 4 goldens regenerated.

| Finding | Fix | File |
|---|---|---|
| **F14** defect | dropped the `color:` argument so the theme supplies it | `mx_loading_state.dart` |
| **F5** | fold past 4 steps, expandable in place, auto-scroll to the deep end | `mx_breadcrumb.dart` |
| **F6** | `rootIcon`, wired to `Icons.home_outlined` | `mx_breadcrumb.dart`, `deck_path_widget.dart` |
| **F7** | `labelLarge` -> `labelMedium` | `mx_breadcrumb.dart` |
| **F8** | both states `onSurfaceVariant`; weight alone distinguishes them | `mx_breadcrumb.dart` |
| **F9** | `subheader` slot, and the deck path moved into it | `mx_content_shell.dart`, `deck_list_screen.dart` |
| **F10** | `leading` slot | `mx_content_shell.dart` |
| **F4** | hairline derived from scroll position | `mx_content_shell.dart` |
| **F1** | hover resolves to 6% accent instead of falling through | `app_button_themes.dart` |
| **F2** | top hairline on the bar | `mx_navigation_bar.dart` |
| **F11** (part) | FAB shape circle -> `RoundedRectangleBorder(AppRadius.lg)` | `app_theme.dart` |

### Two things the render caught that reading did not

**The nav hairline was broken in the middle.** `DecoratedBox` paints its
decoration *behind* its child by default, and `NavigationBar` paints its own
fill, so the first version drew a line at both edges and a gap where the
destinations sat. `DecorationPosition.foreground` fixes it. Only visible in the
golden.

**Material elevation renders as a solid black ring in goldens.** F11 and F15
originally added `elevation` to the FAB and the dialog to carry the design's
`--shadow-card` / `--shadow-overlay`. The regenerated golden showed a dialog
inside a heavy black outline, because `flutter_test` disables real shadows and
draws them as solid shapes.

That turned out to be the smaller reason to back it out. The larger one: **AD-14
makes depth one mechanism** - `shadowsFor`, a `BoxShadow` that the colour audit
can read and that is empty in dark by measurement. Material's `elevation` is a
second, parallel mechanism that is not mode-aware and that no audit rule can
see. Adding it would trade a measurable rule for an unmeasurable one. The shape
change landed; the shadow did not.

## Still open

| # | Why |
|---|---|
| **F15** dialog / FAB shadow | Needs the `shadowsFor` mechanism, which for a dialog means wrapping its content rather than setting a theme property. Deferred deliberately, reason above. |
| **F3** nav indicator role | Design's prose and CSS disagree; Dart follows the prose. No change. |
| **F12** breadcrumb step height | Same - prose says 48, CSS says 36, and 36 breaks the design's own touch-target floor. No change. |
| **F16** scrim opacity | Design 60% flat vs Dart 48/72. Dart's numbers were measured at M4.10j; taking 60% would undo a measured decision to satisfy an unmeasured one. Flagged, not changed. |
| **C8 / C17 / D6 / D7** | `MxProgressBar`, `MxSearchField`, the summary panel and subtree search. Blocked on a `learned` definition that no BR provides, and on a query that does not exist. |
| A7, A13, A14, A16, A18, A19, B10, B12, B13, C5, C7, C10, C12-C15, D1-D5, D8-D15, E1-E12 | Not yet reviewed. |

---

## Complete — all 77 rows

Every row now carries a verdict. Final tally:

| Outcome | Count |
|---|---|
| **match** — nothing to do | 47 |
| **fixed** — Dart moved to the design | 14 |
| **n/a / design-gap** — no counterpart is needed on one side | 8 |
| **blocked on M5** — streak, Start studying, the review and settings screens | 4 |
| **deliberate divergence, recorded** | 4 |

### Fixed in this last pass

- **A16** — Dart had no easing token at all, and the one call site used
  `Curves.decelerate`, which is `cubic-bezier(0, 0, 0.2, 1)` where the design's
  is `(0, 0, 0, 1)`. Close enough to look right and not the same curve. Both of
  the design's curves are now named in `AppDurations`.
- **A7** — the section label's 1.1px tracking was a literal at the call site.
- **D3** — the list had no heading. The design puts "Your decks" / "Sub-decks"
  beside the filter and sort pills, and without it the two pills float above the
  cards with nothing saying what they filter. It sits inside the `Wrap` rather
  than a `Row` above it, because at `textScaler` 2.0 on a 320 screen the label
  and both pills cannot share a line and a `Row` would clip instead of wrapping.

### The four deliberate divergences, all measured

| # | The design says | This repo does | Why the repo wins |
|---|---|---|---|
| C10 | retry is a `secondary` button | primary | Prose, not a value. M4.10n changed it so two states one keystroke apart stop looking like two components. |
| F3 | `mx.css` paints the nav indicator `primary-container` | `secondaryContainer` | The design's own readme says `secondary-container` "used identically for a tab, a filter pill and a chosen verdict". Its CSS and its prose disagree. |
| F12 | `.mx-crumbs__step` is 36px tall | 48 | The design's own usage note says 48, and 36 breaks the touch-target floor its own spacing token declares. |
| F16 | a 60% scrim in both modes | 48% light / 72% dark | M4.10j measured it: a mid scrim over a `#0A082D` page barely registers. |

Plus the two contradictions resolved in the design's favour with a correction
attached — `danger`'s saturation (M4.10p) and the due chip's foreground
(M4.10s), where the design's value failed WCAG and the container it sits on had
no `on*Container` partner to reach for.

**Six contradictions inside the design in total.** That is the single most useful
thing this review produced: "follow the JSX" is not a rule that can be applied
without reading, because the JSX disagrees with itself often enough to need the
tie-break this file states — values win for token values, prose wins for which
token a component reaches for, and measurement wins over both.

### Still blocked, and on what

| Item | Blocked on |
|---|---|
| Streak chip (D6 part) | `review_history` has no writer until M5. A streak that is always zero is worse than no streak. |
| "Start studying" (D6 part) | No session to start until M5. |
| `ReviewScreen` (D13), `SettingsScreen` (D14) | Neither is a built screen; both exist here only as preview harnesses. |
| `MxSearchField` (C17), subtree search (D7) | **Not blocked** — needs a recursive name query, a contract method, a use case and the results UI. The one substantial piece of the design still unbuilt. |
